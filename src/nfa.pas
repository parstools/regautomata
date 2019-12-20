unit Nfa;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fgl;

type

  { TLabel }

  TLabel = class
  private
    fInitStr: string;
  public
    Eps: boolean;
    C: char;
    constructor Create(AInitStr: string);
    function Equals(Obj: TObject) : boolean; override;
    function Clone: TLabel;
    function getDot: string;
  end;

  { TTransition }

  TTransition = class
  public
    Lab: TLabel;
    Dest: integer;
    constructor Create(ALabel: TLabel; ADest: integer);
    function Clone: TTransition;
    function Equals(Obj: TObject) : boolean; override;
    function CloneReverse(newDest: integer): TTransition;
    procedure DeltaIndice(Delta: integer);
    function getDot(ownerIndex: integer): string;
  end;

  { TNfaState }
  TNfaTransitionList = specialize TFPGObjectList<TTransition>;
  TNfaState = class;
  TNfaStateList = specialize TFPGObjectList<TNfaState>;
  TLabelList = specialize TFPGObjectList<TLabel>;

  TNfaState = class
  private
    fStateList: TNfaStateList;
    fTrList: TNfaTransitionList;
    fFinished: boolean;
  protected
  public
    SelfIndex: integer;
    constructor Create(AFinished: boolean);
    destructor Destroy; override;
    procedure GetAllLabels(list: TLabelList);
    function DeltaIndices(Delta: integer): TNfaState;
    procedure AddTransition(t: TTransition);
    procedure AddTransition(AInitStr: string; dest: integer);
    procedure FindTransitionByLabel(lab: TLabel; List: TNfaTransitionList);
    function CountTransitionByLabelAndDest(t: TTransition): integer;
    function Unfinish: TNfaState;
    function Clone: TNfaState;
    function AloneEpsTransition: boolean;
    function OnlyEpsTransitions: boolean;
    function OnlyEpsBackTransitions: boolean;
    function getDot: string;
  end;

  { TNfa }
  TNfa = class
  strict private
    fStates: TNfaStateList;
  public
    StartIndex: integer;
    FinishIndex: integer;
    constructor Create(createState: boolean=true);
    destructor Destroy; override;
    procedure GetAllLabels(list: TLabelList);
    function Clone: TNfa;
    procedure DeltaIndices(Delta: integer);
    procedure AddStateByLabel(AInitStr: string);
    procedure AddStateByLabelAtStart(AInitStr: string);
    procedure Add(other: TNfa);
    procedure AddParallel(other: TNfa);
    procedure MakePlus;
    procedure MakeQuest;
    procedure MakeStar;
    function getDot: string;
    function getState(Index: Integer):TNfaState;
    procedure Check();
    procedure printDot(AFileName: string);
  end;


implementation

{ TLabel }

constructor TLabel.Create(AInitStr: string);
begin
  FInitStr := AInitStr;
  if Length(AInitStr)>1 then
    raise Exception.Create('In this version can''t be fragments');
  if AInitStr = '' then
  begin
    Eps := True;
    C := #0;
  end
  else
  begin
    Eps := False;
    C := AInitStr[1];
  end;
end;

function TLabel.Equals(Obj: TObject): boolean;
var
  other: TLabel;
begin
  other:=Obj as TLabel;
  if Eps then
    Result:=other.Eps
  else
    Result:=other.C=C;
end;

function TLabel.Clone: TLabel;
begin
  Result := TLabel.Create(FInitStr);
end;

function TLabel.getDot: string;
begin
  if Eps then
    Result := '&epsilon;'
  else
    Result := C;
end;

{ TTransition }

constructor TTransition.Create(ALabel: TLabel; ADest: integer);
begin
  Lab := ALabel;
  Dest := ADest;
end;

function TTransition.Clone: TTransition;
begin
  Result := TTransition.Create(Lab.Clone, Dest);
end;

function TTransition.Equals(Obj: TObject): boolean;
var
  other: TTransition;
begin
  other:=Obj as TTransition;
  Result:=Lab.Equals(other.Lab) and (Dest=other.Dest);
end;

function TTransition.CloneReverse(newDest: integer): TTransition;
begin
  Result := TTransition.Create(Lab.Clone, newDest);
end;

procedure TTransition.DeltaIndice(Delta: integer);
begin
  Inc(Dest, Delta);
end;

function TTransition.getDot(ownerIndex: integer): string;
begin
  Result := IntToStr(ownerIndex)+'->'+IntToStr(Dest)+' [ label = <'+
    Lab.getDot()+'> ];';
end;

{ TNfaState }

constructor TNfaState.Create(AFinished: boolean);
begin
  fTrList := TNfaTransitionList.Create(True);
  fFinished := AFinished;
end;

destructor TNfaState.Destroy;
begin
  fTrList.Free;
  inherited Destroy;
end;

procedure TNfaState.GetAllLabels(list: TLabelList);
var
  i: integer;
begin
  for i:=0 to fTrList.Count-1 do
    list.Add(fTrList[i].Lab);
end;

function TNfaState.DeltaIndices(Delta: integer): TNfaState;
var
  i: integer;
begin
  for i := 0 to FTrList.Count-1 do
    FTrList[i].DeltaIndice(Delta);
  Inc(SelfIndex, Delta);
  Result := self;
end;

procedure TNfaState.AddTransition(t: TTransition);
begin
  if CountTransitionByLabelAndDest(t)=0 then
    FTrList.Add(t);
end;

procedure TNfaState.AddTransition(AInitStr: string; dest: integer);
begin
  addTransition(TTransition.Create(TLabel.Create(AInitStr), dest));
end;

procedure TNfaState.FindTransitionByLabel(lab: TLabel; List: TNfaTransitionList);
var
  i: integer;
begin
  for i:=0 to fTrList.Count-1 do
     if fTrList[i].Lab.Equals(lab) then
       List.Add(fTrList[i]);
end;

function TNfaState.CountTransitionByLabelAndDest(t: TTransition): integer;
var
  i: integer;
begin
  Result:=0;
  for i:=0 to fTrList.Count-1 do
     if fTrList[i].Equals(t) then
       inc(Result);
end;

function TNfaState.Unfinish: TNfaState;
begin
  fFinished := False;
  Result := self;
end;

function TNfaState.Clone: TNfaState;
var
  i: integer;
begin
  Result := TNfaState.Create(fFinished);
  Result.SelfIndex := SelfIndex;
  Result.fFinished:=fFinished;
  Result.fStateList:=nil; //has not owner yet
  for i := 0 to FTrList.Count-1 do
  begin
    Result.AddTransition(fTrList[i].Clone);
  end;
end;

function TNfaState.AloneEpsTransition: boolean;
begin
  if fTrList.Count>1 then
    Result := False
  else
    Result := fTrList[0].Lab.Eps;
end;

function TNfaState.OnlyEpsTransitions: boolean;
var
  i: integer;
begin
  Result := False;
  for i := 0 to fTrList.Count-1 do
    if not fTrList[i].Lab.Eps then
      exit;
  Result := True;
end;

function TNfaState.OnlyEpsBackTransitions: boolean;
var
  i,j: integer;
  state: TNfaState;
  t: TTransition;
begin
  Result := False;
  for i:=0 to fStateList.Count-1 do
  begin
     state:=fStateList[i];
     for j := 0 to state.fTrList.Count-1 do
     begin
       t:=state.fTrList[j];
       if (t.Dest=SelfIndex) and not t.Lab.Eps then
          exit;
     end;
  end;
  Result := True;
end;

function TNfaState.getDot: string;
var
  i: integer;
begin
  Result := '';
  for i := 0 to fTrList.Count-1 do
    Result := Result+fTrList[i].getDot(SelfIndex)+#10;
end;

{ TNfa }
constructor TNfa.Create(createState: boolean=true);
var
  firstState: TNfaState;
begin
  fStates := TNfaStateList.Create(True);
  if createState then
  begin
    firstState := TNfaState.Create(True);
    firstState.SelfIndex := 0;
    firstState.fStateList := fStates;
    fStates.Add(firstState);
  end;
  StartIndex := 0;
  FinishIndex := 0;
end;

destructor TNfa.Destroy;
begin
  fStates.Free;
  inherited Destroy;
end;

procedure TNfa.GetAllLabels(list: TLabelList);
var
    i,j: integer;
    State: TNfaState;
begin
  for i:=0 to fStates.Count-1 do
  begin
    fStates[i].GetAllLabels(list);
  end;
end;

function TNfa.Clone: TNfa;
var
  i: integer;
  state: TNfaState;
begin
  Result := TNfa.Create(false);
  for i := 0 to FStates.Count-1 do
  begin
    state:=FStates[i].Clone;
    state.fStateList:=Result.fStates;
    Result.fStates.Add(state);
  end;
  Result.StartIndex := StartIndex;
  Result.FinishIndex := FinishIndex;
end;

procedure TNfa.DeltaIndices(Delta: integer);
var
  i: integer;
begin
  for i := 0 to FStates.Count-1 do
    FStates[i].DeltaIndices(Delta);
  inc(StartIndex,Delta);
  inc(FinishIndex,Delta);
end;

procedure TNfa.AddStateByLabel(AInitStr: string);
var
  newState: TNfaState;
begin
  fStates[FinishIndex].Unfinish;
  newState := TNfaState.Create(True);
  fStates.Add(newState);
  fStates[FinishIndex].addTransition(AInitStr, fStates.Count-1);
  newState.SelfIndex := fStates.Count-1;
  newState.fStateList := fStates;
  FinishIndex := fStates.Count-1;
end;

procedure TNfa.AddStateByLabelAtStart(AInitStr: string);
var
  newState: TNfaState;
begin
  DeltaIndices(1);
  newState := TNfaState.Create(False);
  fStates.Insert(0, newState);
  newState.SelfIndex := 0;
  newState.fStateList := fStates;
  newState.AddTransition(AInitStr, StartIndex);
  StartIndex := 0;
end;

procedure TNfa.Add(other: TNfa);
var
  i, delta: integer;
  st: TNfaState;
begin
  delta := fStates.Count;
  for i := 0 to other.fStates.Count-1 do
  begin
    st := other.fStates[i].Clone.DeltaIndices(delta).Unfinish;
    st.fStateList:=fStates;
    FStates.Add(st);
  end;
  fStates[FinishIndex].AddTransition('', delta);
  FinishIndex := other.FinishIndex+delta;
end;

procedure TNfa.AddParallel(other: TNfa);
var
  i: integer;
  cloned: TNfa;
begin
  if not fStates[StartIndex].OnlyEpsTransitions then
    AddStateByLabelAtStart('');
  if not fStates[FinishIndex].OnlyEpsBackTransitions then
    AddStateByLabel('');
  cloned := other.Clone;
  cloned.fStates[cloned.FinishIndex].Unfinish;
  cloned.DeltaIndices(fStates.Count);
  for i := 0 to cloned.fStates.Count-1 do
  begin
    cloned.fStates[i].fStateList:=fStates;
    fStates.Add(cloned.fStates[i]);
  end;
  fStates[StartIndex].AddTransition('', cloned.StartIndex);
  fStates[cloned.FinishIndex].AddTransition('', FinishIndex);
end;

procedure TNfa.MakePlus;
begin
  if not fStates[FinishIndex].OnlyEpsBackTransitions then
    AddStateByLabel('');
  fStates[FinishIndex].AddTransition('',StartIndex);
end;

procedure TNfa.MakeQuest;
begin
  fStates[StartIndex].AddTransition('',FinishIndex);
end;

procedure TNfa.MakeStar;
begin
  MakePlus;
  MakeQuest;
end;

function TNfa.getDot: string;
var
  i: integer;
begin
  Result := 'digraph a {'#10'        rankdir=LR;'#10;
  for i := 0 to fStates.Count-1 do
  begin
    if fStates[i].fFinished then
      Result := Result+'node [shape = doublecircle] '+IntToStr(fStates[i].SelfIndex)+#10
    else
      Result := Result+'node [shape = circle] '+IntToStr(fStates[i].SelfIndex)+#10;
  end;
  for i := 0 to fStates.Count-1 do
    Result := Result+fStates[i].getDot;
  Result := Result+'}';
end;

function TNfa.getState(Index: Integer): TNfaState;
begin
  Result := fStates[Index];
end;

procedure TNfa.Check();
var
  i, j, k: integer;
  fc, fcErr, err0: integer;
  emptyErr,emptyBackErr: integer;
  doubleErr: integer;
  t, tback: TTransition;
  destState: TNfaState;
  backCounts: array of integer;
  trCount: integer;
begin
  fc := 0;
  fcErr := 0;
  err0 := 0;
  emptyErr := 0;
  emptyBackErr := 0;
  doubleErr := 0;
  SetLength(backCounts,fStates.Count);
  for i := 0 to fStates.Count-1 do
  begin
    if fStates[i].fFinished then
    begin
      Inc(fc);
      if FinishIndex<>i then inc(fcErr);
    end else
    begin
      if fStates[i].fTrList.Count=0 then inc(emptyErr);
      if FinishIndex=i then inc(fcErr);
    end;
    if fStates[i].SelfIndex<>i then
      Inc(err0);
    for j:= 0 to fStates[i].fTrList.Count-1 do
    begin
       inc(backCounts[fStates[i].fTrList[j].Dest]);
       trCount:=fStates[i].CountTransitionByLabelAndDest(fStates[i].fTrList[j]);
       if trCount>1 then inc(doubleErr);
    end;
  end;
  for i := 0 to High(backCounts) do
  begin
    if (i<>StartIndex) and (backCounts[i]=0) then
       inc(emptyBackErr);
  end;

  if (fc<>1) then
    raise Exception.Create('must be one finish state is '+IntToStr(fc));
  if (fcErr>0) then
    raise Exception.Create('mismatch finished bool and index');
  if (err0>0) then
    raise Exception.Create('FSelfIndex mismatch');
  if (emptyErr>0) then
    raise Exception.Create('not finished state has zero transitions');
  if (emptyBackErr>0) then
    raise Exception.Create('not started state has zero back transitions');
  if (doubleErr>0) then
    raise Exception.Create('doubled transition');
end;

procedure TNfa.printDot(AFileName: string);
var
  f: TextFile;
begin
  AssignFile(f, AFileName);
  Rewrite(f);
  write(f, getDot);
  CloseFile(f);
end;

end.
