unit Fa;

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
    property InitStr: string read fInitStr;
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

  TTransitionList = specialize TFPGObjectList<TTransition>;
  TState = class;
  TStateList = specialize TFPGObjectList<TState>;
  TLabelList = specialize TFPGObjectList<TLabel>;

  TState = class
  public
    StateList: TStateList;
    Finished: boolean;
    TrList: TTransitionList;
    SelfIndex: integer;
    constructor Create(AFinished: boolean);
    destructor Destroy; override;
    procedure GetAllLabels(list: TLabelList);
    function DeltaIndices(Delta: integer): TState;
    procedure AddTransition(t: TTransition);
    procedure AddTransition(AInitStr: string; dest: integer);
    procedure FindTransitionByLabel(lab: TLabel; List: TTransitionList);
    function CountTransitionByLabelAndDest(t: TTransition): integer;
    function Unfinish: TState;
    function Clone: TState;
    function AloneEpsTransition: boolean;
    function OnlyEpsTransitions: boolean;
    function OnlyEpsBackTransitions: boolean;
    function getDot: string;
  end;

  { TFa }

  TFa = class
  private
    function GetItems(i : Longint): TState;
  protected
    fStates: TStateList;
    procedure CloneStates(dest: TFa);
  public
    constructor Create(createState: boolean = True);
    destructor Destroy; override;
    procedure GetAllLabels(list: TLabelList);
    procedure DeltaIndices(Delta: integer);
    function getDot: string;
    function getState(Index: integer): TState;
    procedure printDot(AFileName: string);
    function Count: integer;
    property Items[i : Longint]: TState read GetItems; Default;
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

{ TState }

constructor TState.Create(AFinished: boolean);
begin
  TrList := TTransitionList.Create(True);
  Finished := AFinished;
end;

destructor TState.Destroy;
begin
  TrList.Free;
  inherited Destroy;
end;

procedure TState.GetAllLabels(list: TLabelList);
var
  i: integer;
begin
  for i:=0 to TrList.Count-1 do
    list.Add(TrList[i].Lab);
end;

function TState.DeltaIndices(Delta: integer): TState;
var
  i: integer;
begin
  for i := 0 to TrList.Count-1 do
    TrList[i].DeltaIndice(Delta);
  Inc(SelfIndex, Delta);
  Result := self;
end;

procedure TState.AddTransition(t: TTransition);
begin
  if CountTransitionByLabelAndDest(t)=0 then
    TrList.Add(t);
end;

procedure TState.AddTransition(AInitStr: string; dest: integer);
begin
  addTransition(TTransition.Create(TLabel.Create(AInitStr), dest));
end;

procedure TState.FindTransitionByLabel(lab: TLabel; List: TTransitionList);
var
  i: integer;
begin
  for i:=0 to TrList.Count-1 do
     if TrList[i].Lab.Equals(lab) then
       List.Add(TrList[i]);
end;

function TState.CountTransitionByLabelAndDest(t: TTransition): integer;
var
  i: integer;
begin
  Result:=0;
  for i:=0 to TrList.Count-1 do
     if TrList[i].Equals(t) then
       inc(Result);
end;

function TState.Unfinish: TState;
begin
  Finished := False;
  Result := self;
end;

function TState.Clone: TState;
var
  i: integer;
begin
  Result := TState.Create(Finished);
  Result.SelfIndex := SelfIndex;
  Result.Finished:=Finished;
  Result.StateList:=nil; //has not owner yet
  for i := 0 to TrList.Count-1 do
  begin
    Result.AddTransition(TrList[i].Clone);
  end;
end;

function TState.AloneEpsTransition: boolean;
begin
  if TrList.Count>1 then
    Result := False
  else
    Result := TrList[0].Lab.Eps;
end;

function TState.OnlyEpsTransitions: boolean;
var
  i: integer;
begin
  Result := False;
  for i := 0 to TrList.Count-1 do
    if not TrList[i].Lab.Eps then
      exit;
  Result := True;
end;

function TState.OnlyEpsBackTransitions: boolean;
var
  i,j: integer;
  state: TState;
  t: TTransition;
begin
  Result := False;
  for i:=0 to StateList.Count-1 do
  begin
     state:=StateList[i];
     for j := 0 to state.TrList.Count-1 do
     begin
       t:=state.TrList[j];
       if (t.Dest=SelfIndex) and not t.Lab.Eps then
          exit;
     end;
  end;
  Result := True;
end;

function TState.getDot: string;
var
  i: integer;
begin
  Result := '';
  for i := 0 to TrList.Count-1 do
    Result := Result+TrList[i].getDot(SelfIndex)+#10;
end;

function TFa.GetItems(i : Longint): TState;
begin
  Result:=fStates[i];
end;

procedure TFa.CloneStates(dest: TFa);
var
  i: integer;
  state: TState;
begin
  for i := 0 to FStates.Count-1 do
  begin
    state:=FStates[i].Clone;
    state.StateList:=dest.fStates;
    dest.fStates.Add(state);
  end;
end;

constructor TFa.Create(createState: boolean);
var
  firstState: TState;
begin
  fStates := TStateList.Create(True);
  if createState then
  begin
    firstState := TState.Create(True);
    firstState.SelfIndex := 0;
    firstState.StateList := fStates;
    fStates.Add(firstState);
  end;
end;

destructor TFa.Destroy;
begin
  fStates.Free;
  inherited Destroy;
end;

procedure TFa.GetAllLabels(list: TLabelList);
var
  i, j: integer;
  State: TState;
begin
  for i := 0 to fStates.Count-1 do
  begin
    fStates[i].GetAllLabels(list);
  end;
end;

procedure TFa.DeltaIndices(Delta: integer);
var
  i: integer;
begin
  for i := 0 to FStates.Count-1 do
    FStates[i].DeltaIndices(Delta);
end;

function TFa.getDot: string;
var
  i: integer;
begin
  Result := 'digraph a {'#10'        rankdir=LR;'#10;
  for i := 0 to fStates.Count-1 do
  begin
    if fStates[i].Finished then
      Result := Result+'node [shape = doublecircle] '+IntToStr(fStates[i].SelfIndex)+#10
    else
      Result := Result+'node [shape = circle] '+IntToStr(fStates[i].SelfIndex)+#10;
  end;
  for i := 0 to fStates.Count-1 do
    Result := Result+fStates[i].getDot;
  Result := Result+'}';
end;

function TFa.getState(Index: integer): TState;
begin
  Result := fStates[Index];
end;

procedure TFa.printDot(AFileName: string);
var
  f: TextFile;
begin
  AssignFile(f, AFileName);
  Rewrite(f);
  write(f, getDot);
  CloseFile(f);
end;

function TFa.Count: integer;
begin
  Result:=fStates.Count;
end;

end.

