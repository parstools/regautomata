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
  public
    fStateList: TNfaStateList;//@todo rename
    fFinished: boolean;//@todo rename
    fTrList: TNfaTransitionList;//@todo rename
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

  { TFa }

  TFa = class
  protected
    fStates: TNfaStateList;
    procedure CloneStates(dest: TFa);
  public
    constructor Create(createState: boolean = True);
    destructor Destroy; override;
    procedure GetAllLabels(list: TLabelList);
    procedure DeltaIndices(Delta: integer);
    function getDot: string;
    function getState(Index: integer): TNfaState;
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

procedure TFa.CloneStates(dest: TFa);
var
  i: integer;
  state: TNfaState;
begin
  for i := 0 to FStates.Count-1 do
  begin
    state:=FStates[i].Clone;
    state.fStateList:=dest.fStates;
    dest.fStates.Add(state);
  end;
end;

constructor TFa.Create(createState: boolean);
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
end;

destructor TFa.Destroy;
begin
  fStates.Free;
  inherited Destroy;
end;

procedure TFa.GetAllLabels(list: TLabelList);
var
  i, j: integer;
  State: TNfaState;
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
    if fStates[i].fFinished then
      Result := Result+'node [shape = doublecircle] '+IntToStr(fStates[i].SelfIndex)+#10
    else
      Result := Result+'node [shape = circle] '+IntToStr(fStates[i].SelfIndex)+#10;
  end;
  for i := 0 to fStates.Count-1 do
    Result := Result+fStates[i].getDot;
  Result := Result+'}';
end;

function TFa.getState(Index: integer): TNfaState;
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

end.

