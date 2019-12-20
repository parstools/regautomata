unit Nfa;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fgl;

type

  { TLabel }

  TLabel = class
  private
    fEps: boolean;
    fC: char;
    fInitStr: string;
  public
    constructor Create(AInitStr: string);
    function Equals(Obj: TObject) : boolean; override;
    function Clone: TLabel;
    function getDot: string;
  end;

  { TTransition }

  TTransition = class
  private
    fLabel: TLabel;
    fDest: integer;
  public
    constructor Create(ALabel: TLabel; ADest: integer);
    function Clone: TTransition;
    function Equals(Obj: TObject) : boolean; override;
    function CloneReverse(newDest: integer): TTransition;
    procedure DeltaIndice(Delta: integer);
    function getDot(ownerIndex: integer): string;
  end;

  { TNfaState }
  TTransitionList = specialize TFPGObjectList<TTransition>;
  TNfaState = class;
  TNfaStateList = specialize TFPGObjectList<TNfaState>;

  TNfaState = class
  private
    fSelfIndex: integer;
    fStateList: TNfaStateList;
    fTrList: TTransitionList;
    fFinished: boolean;
  protected
  public
    constructor Create(AFinished: boolean);
    destructor Destroy; override;
    function DeltaIndices(Delta: integer): TNfaState;
    procedure AddTransition(t: TTransition);
    procedure AddTransition(AInitStr: string; dest: integer);
    procedure FindTransitionByLabel(lab: TLabel; List: TTransitionList);
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
  private
    fStates: TNfaStateList;
    fStartIndex: integer;
    fFinishIndex: integer;
  public
    constructor Create(createState: boolean=true);
    destructor Destroy; override;
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
    FEps := True;
    FC := #0;
  end
  else
  begin
    FEps := False;
    FC := AInitStr[1];
  end;
end;

function TLabel.Equals(Obj: TObject): boolean;
var
  other: TLabel;
begin
  other:=Obj as TLabel;
  if fEps then
    Result:=other.fEps
  else
    Result:=other.fC=fC;
end;

function TLabel.Clone: TLabel;
begin
  Result := TLabel.Create(FInitStr);
end;

function TLabel.getDot: string;
begin
  if fEps then
    Result := '&epsilon;'
  else
    Result := fC;
end;

{ TTransition }

constructor TTransition.Create(ALabel: TLabel; ADest: integer);
begin
  FLabel := ALabel;
  FDest := ADest;
end;

function TTransition.Clone: TTransition;
begin
  Result := TTransition.Create(FLabel.Clone, FDest);
end;

function TTransition.Equals(Obj: TObject): boolean;
var
  other: TTransition;
begin
  other:=Obj as TTransition;
  Result:=fLabel.Equals(other.fLabel) and (fDest=other.fDest);
end;

function TTransition.CloneReverse(newDest: integer): TTransition;
begin
  Result := TTransition.Create(FLabel.Clone, newDest);
end;

procedure TTransition.DeltaIndice(Delta: integer);
begin
  Inc(FDest, Delta);
end;

function TTransition.getDot(ownerIndex: integer): string;
begin
  Result := IntToStr(ownerIndex)+'->'+IntToStr(fDest)+' [ label = <'+
    fLabel.getDot()+'> ];';
end;

{ TNfaState }

constructor TNfaState.Create(AFinished: boolean);
begin
  fTrList := TTransitionList.Create(True);
  fFinished := AFinished;
end;

destructor TNfaState.Destroy;
begin
  fTrList.Free;
  inherited Destroy;
end;

function TNfaState.DeltaIndices(Delta: integer): TNfaState;
var
  i: integer;
begin
  for i := 0 to FTrList.Count-1 do
    FTrList[i].DeltaIndice(Delta);
  Inc(fSelfIndex, Delta);
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

procedure TNfaState.FindTransitionByLabel(lab: TLabel; List: TTransitionList);
var
  i: integer;
begin
  for i:=0 to fTrList.Count-1 do
     if fTrList[i].fLabel.Equals(lab) then
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
  Result.fSelfIndex := fSelfIndex;
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
    Result := fTrList[0].fLabel.fEps;
end;

function TNfaState.OnlyEpsTransitions: boolean;
var
  i: integer;
begin
  Result := False;
  for i := 0 to fTrList.Count-1 do
    if not fTrList[i].fLabel.fEps then
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
       if (t.fDest=fSelfIndex) and not t.fLabel.fEps then
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
    Result := Result+fTrList[i].getDot(fSelfIndex)+#10;
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
    firstState.fSelfIndex := 0;
    firstState.fStateList := fStates;
    fStates.Add(firstState);
  end;
  fStartIndex := 0;
  fFinishIndex := 0;
end;

destructor TNfa.Destroy;
begin
  fStates.Free;
  inherited Destroy;
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
  Result.fStartIndex := fStartIndex;
  Result.fFinishIndex := fFinishIndex;
end;

procedure TNfa.DeltaIndices(Delta: integer);
var
  i: integer;
begin
  for i := 0 to FStates.Count-1 do
    FStates[i].DeltaIndices(Delta);
  inc(fStartIndex,Delta);
  inc(fFinishIndex,Delta);
end;

procedure TNfa.AddStateByLabel(AInitStr: string);
var
  newState: TNfaState;
begin
  fStates[fFinishIndex].Unfinish;
  newState := TNfaState.Create(True);
  fStates.Add(newState);
  fStates[fFinishIndex].addTransition(AInitStr, fStates.Count-1);
  newState.fSelfIndex := fStates.Count-1;
  newState.fStateList := fStates;
  fFinishIndex := fStates.Count-1;
end;

procedure TNfa.AddStateByLabelAtStart(AInitStr: string);
var
  newState: TNfaState;
begin
  DeltaIndices(1);
  newState := TNfaState.Create(False);
  fStates.Insert(0, newState);
  newState.fSelfIndex := 0;
  newState.fStateList := fStates;
  newState.AddTransition(AInitStr, fStartIndex);
  fStartIndex := 0;
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
  fStates[fFinishIndex].AddTransition('', delta);
  fFinishIndex := other.fFinishIndex+delta;
end;

procedure TNfa.AddParallel(other: TNfa);
var
  i: integer;
  cloned: TNfa;
begin
  if not fStates[fStartIndex].OnlyEpsTransitions then
    AddStateByLabelAtStart('');
  if not fStates[fFinishIndex].OnlyEpsBackTransitions then
    AddStateByLabel('');
  cloned := other.Clone;
  cloned.fStates[cloned.fFinishIndex].Unfinish;
  cloned.DeltaIndices(fStates.Count);
  for i := 0 to cloned.fStates.Count-1 do
  begin
    cloned.fStates[i].fStateList:=fStates;
    fStates.Add(cloned.fStates[i]);
  end;
  fStates[fStartIndex].AddTransition('', cloned.fStartIndex);
  fStates[cloned.fFinishIndex].AddTransition('', fFinishIndex);
end;

procedure TNfa.MakePlus;
begin
  if not fStates[fFinishIndex].OnlyEpsBackTransitions then
    AddStateByLabel('');
  fStates[fFinishIndex].AddTransition('',fStartIndex);
end;

procedure TNfa.MakeQuest;
begin
  fStates[fStartIndex].AddTransition('',fFinishIndex);
end;

procedure TNfa.MakeStar;
begin

end;

function TNfa.getDot: string;
var
  i: integer;
begin
  Result := 'digraph a {'#10'        rankdir=LR;'#10;
  for i := 0 to fStates.Count-1 do
  begin
    if fStates[i].fFinished then
      Result := Result+'node [shape = doublecircle] '+IntToStr(fStates[i].fSelfIndex)+#10
    else
      Result := Result+'node [shape = circle] '+IntToStr(fStates[i].fSelfIndex)+#10;
  end;
  for i := 0 to fStates.Count-1 do
    Result := Result+fStates[i].getDot;
  Result := Result+'}';
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
      if fFinishIndex<>i then inc(fcErr);
    end else
    begin
      if fStates[i].fTrList.Count=0 then inc(emptyErr);
      if fFinishIndex=i then inc(fcErr);
    end;
    if fStates[i].fSelfIndex<>i then
      Inc(err0);
    for j:= 0 to fStates[i].fTrList.Count-1 do
    begin
       inc(backCounts[fStates[i].fTrList[j].fDest]);
       trCount:=fStates[i].CountTransitionByLabelAndDest(fStates[i].fTrList[j]);
       if trCount>1 then inc(doubleErr);
    end;
  end;
  for i := 0 to High(backCounts) do
  begin
    if (i<>fStartIndex) and (backCounts[i]=0) then
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
