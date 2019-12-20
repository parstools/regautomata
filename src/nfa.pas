unit Nfa;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fgl, Fa;

type
  { TNfa }
  TNfa = class(TFa)
  public
    StartIndex: integer;
    FinishIndex: integer;
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
    procedure Check();
  end;

implementation

{ TNfa }
constructor TNfa.Create(createState: boolean=true);
begin
  inherited Create(createState);
  StartIndex := 0;
  FinishIndex := 0;
end;

destructor TNfa.Destroy;
begin
  inherited Destroy;
end;

function TNfa.Clone: TNfa;
begin
  Result := TNfa.Create(false);
  CloneStates(Result);
  Result.StartIndex := StartIndex;
  Result.FinishIndex := FinishIndex;
end;

procedure TNfa.DeltaIndices(Delta: integer);
begin
  inherited DeltaIndices(Delta);
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

end.
