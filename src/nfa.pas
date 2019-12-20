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
    function CloneReverse(newDest: integer): TTransition;
    procedure DeltaIndice(Delta: integer);
    function getDot(ownerIndex: integer; back: boolean = False): string;
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
    fTrBackList: TTransitionList;
    fFinished: boolean;
  protected
    procedure AddBackTransition(t: TTransition);
  public
    constructor Create(AFinished: boolean);
    destructor Destroy; override;
    function DeltaIndices(Delta: integer): TNfaState;
    procedure AddTransition(t: TTransition);
    procedure AddTransition(AInitStr: string; dest: integer);
    function Unfinish: TNfaState;
    function Clone: TNfaState;
    function AloneEpsTransition: boolean;
    function AloneEpsBackTransition: boolean;
    function OnlyEpsTransitions: boolean;
    function OnlyEpsBackTransitions: boolean;
    function getDot(back: boolean = False): string;
    function findTransitionByDest(dest: integer; back: boolean): TTransition;
    procedure UpdateBackTransitions;
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
    function getDot(back: boolean = False): string;
    procedure UpdateBackTransitions;
    procedure Check();
    procedure printDot(AFileName: string; back: boolean = False);
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

function TTransition.CloneReverse(newDest: integer): TTransition;
begin
  Result := TTransition.Create(FLabel.Clone, newDest);
end;

procedure TTransition.DeltaIndice(Delta: integer);
begin
  Inc(FDest, Delta);
end;

function TTransition.getDot(ownerIndex: integer; back: boolean = False): string;
begin
  if back then
    Result := IntToStr(fDest)+'->'+IntToStr(ownerIndex)+' [ label = <'+
      fLabel.getDot()+'> ];'
  else
    Result := IntToStr(ownerIndex)+'->'+IntToStr(fDest)+' [ label = <'+
      fLabel.getDot()+'> ];';
end;

{ TNfaState }

constructor TNfaState.Create(AFinished: boolean);
begin
  fTrList := TTransitionList.Create(True);
  fTrBackList := TTransitionList.Create(False);
  fFinished := AFinished;
end;

destructor TNfaState.Destroy;
begin
  fTrList.Free;
  fTrBackList.Free;
  inherited Destroy;
end;

function TNfaState.DeltaIndices(Delta: integer): TNfaState;
var
  i: integer;
begin
  for i := 0 to FTrList.Count-1 do
    FTrList[i].DeltaIndice(Delta);
  for i := 0 to fTrBackList.Count-1 do
    fTrBackList[i].DeltaIndice(Delta);
  Inc(fSelfIndex, Delta);
  Result := self;
end;

procedure TNfaState.AddTransition(t: TTransition);
begin
  FTrList.Add(t);
  //can't be UpdateBackTransitions because at this stage can be add transition to alone state
end;

procedure TNfaState.AddBackTransition(t: TTransition);
begin
  fTrBackList.Add(t);
end;

procedure TNfaState.AddTransition(AInitStr: string; dest: integer);
begin
  addTransition(TTransition.Create(TLabel.Create(AInitStr), dest));
  UpdateBackTransitions;
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
  for i := 0 to fTrBackList.Count-1 do
  begin
    Result.AddBackTransition(fTrBackList[i].Clone);
  end;
end;

function TNfaState.AloneEpsTransition: boolean;
begin
  if fTrList.Count = 0 then
    raise Exception.Create('empty transition list');
  if fTrList.Count>1 then
    Result := False
  else
    Result := fTrList[0].fLabel.fEps;
end;

function TNfaState.AloneEpsBackTransition: boolean;
begin
  if fTrBackList.Count = 0 then
    raise Exception.Create('empty back transition list');
  if fTrBackList.Count>1 then
    Result := False
  else
    Result := fTrBackList[0].fLabel.fEps;
end;

function TNfaState.OnlyEpsTransitions: boolean;
var
  i: integer;
begin
  if fTrList.Count = 0 then
    raise Exception.Create('empty transition list');
  Result := False;
  for i := 0 to fTrList.Count-1 do
    if not fTrList[i].fLabel.fEps then
      exit;
  Result := True;
end;

function TNfaState.OnlyEpsBackTransitions: boolean;
var
  i: integer;
begin
  if fTrBackList.Count = 0 then
    raise Exception.Create('empty back transition list');
  Result := False;
  for i := 0 to fTrBackList.Count-1 do
    if not fTrBackList[i].fLabel.fEps then
      exit;
  Result := True;
end;

function TNfaState.getDot(back: boolean = False): string;
var
  i: integer;
begin
  Result := '';
  if back then
    for i := 0 to fTrBackList.Count-1 do
      Result := Result+fTrBackList[i].getDot(fSelfIndex, back)+#10
  else
    for i := 0 to fTrList.Count-1 do
      Result := Result+fTrList[i].getDot(fSelfIndex, back)+#10;
end;

function TNfaState.findTransitionByDest(dest: integer; back: boolean): TTransition;
var
  i: integer;
begin
  Result := nil;
  if back then
  begin
    for i := 0 to fTrBackList.Count-1 do
      if fTrBackList[i].fDest = dest then
      begin
        if Result<>nil then
          raise Exception.Create('double transition');
        Result := fTrBackList[i];
      end;
  end
  else
  begin
    for i := 0 to fTrList.Count-1 do
      if fTrList[i].fDest = dest then
      begin
        if Result<>nil then
          raise Exception.Create('double transition');
        Result := fTrList[i];
      end;
  end;
end;

procedure TNfaState.UpdateBackTransitions;
var
  i: integer;
  t, tback: TTransition;
  destState: TNfaState;
begin
  Assert(fStateList<>nil);
  for i := 0 to fTrList.Count-1 do
  begin
    t := fTrList[i];
    destState := fStateList[t.fDest];
    tback := destState.findTransitionByDest(fSelfIndex, True);
    if tback = nil then
      destState.AddBackTransition(t.CloneReverse(fSelfIndex));
  end;
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
begin
  Result := TNfa.Create(false);
  for i := 0 to FStates.Count-1 do
    Result.FStates.Add(FStates[i].Clone);
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
  FStates[fFinishIndex].Unfinish;
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
var
  oldFinished: integer;
begin
  oldFinished:=fFinishIndex;
  AddStateByLabel('');
  fStates[fFinishIndex].AddTransition('',oldFinished);
end;

procedure TNfa.MakeQuest;
begin
  fStates[fStartIndex].AddTransition('',fFinishIndex);
end;

procedure TNfa.MakeStar;
begin

end;

function TNfa.getDot(back: boolean = False): string;
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
    Result := Result+fStates[i].getDot(back);
  Result := Result+'}';
end;

procedure TNfa.UpdateBackTransitions;
var
  i: integer;
begin
  for i := 0 to fStates.Count-1 do
    fStates[i].UpdateBackTransitions;
end;

procedure TNfa.Check();
var
  i, j: integer;
  fc, fcErr, err0, err1, err2: integer;
  t, tback: TTransition;
  destState: TNfaState;
begin
  fc := 0;
  fcErr := 0;
  err0 := 0;
  err1 := 0;
  err2 := 0;
  for i := 0 to fStates.Count-1 do
  begin
    if fStates[i].fFinished then
    begin
      Inc(fc);
      if fFinishIndex<>i then inc(fcErr);
    end else
    begin
      if fFinishIndex=i then inc(fcErr);
    end;
    if fStates[i].fSelfIndex<>i then
      Inc(err0);
    for j := 0 to fStates[i].fTrList.Count-1 do
    begin
      t := fStates[i].fTrList[j];
      destState := fStates[t.fDest];
      tback := destState.findTransitionByDest(i, True);
      if tback = nil then
        Inc(err1);
    end;
    for j := 0 to fStates[i].fTrBackList.Count-1 do
    begin
      t := fStates[i].fTrBackList[j];
      destState := fStates[t.fDest];
      tback := destState.findTransitionByDest(i, False);
      if tback = nil then
        Inc(err2);
    end;
  end;
  if (fc<>1) then
    raise Exception.Create('must be one finish state is '+IntToStr(fc));
  if (fcErr>0) then
    raise Exception.Create('mismatch finished bool and index');
  if (err0>0) then
    raise Exception.Create('FSelfIndex mismatch');
  if (err1>0) or (err2>0) then
    raise Exception.Create('transitions and back transitions mismatch');
end;

procedure TNfa.printDot(AFileName: string; back: boolean = False);
var
  f: TextFile;
begin
  AssignFile(f, AFileName);
  Rewrite(f);
  write(f, getDot(back));
  CloseFile(f);
end;

end.
