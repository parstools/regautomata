unit NfaConverter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fgl, Fa, Nfa, Dfa;

type
  { TLabelSet }

  TLabelSet = class
  private
    fLabelList: TLabelList;
    function GetLabel(i : Longint): TLabel;
  public
    constructor Create();
    destructor Destroy; override;
    function GetIndex(ALabel: TLabel): integer;
    function Count : integer;
    function Add(ALabel: TLabel): integer;
    property Items[i : Longint]: TLabel read GetLabel; Default;
  end;

  { TNfaSet }
  TNfaList = specialize TFPGObjectList<TNfaState>;

  TNfaSet = class
  private
    fNfaList: TNfaList;
    fBits: TBits;
  public
    constructor Create;
    destructor Destroy; override;
    function Equals(Obj: TObject): boolean; override;
    procedure Add(nfaState: TNfaState);
    procedure eClosure(aNfa: TNfa);
    function nonEmpty: boolean;
    procedure TransitTo(aNfa: TNfa; ALabel:TLabel; DestSet:TNfaSet);
  end;

  { TSetSet }
  TSetList = specialize TFPGObjectList<TNfaSet>;

  TSetSet = class
  strict private
    fSetList: TSetList;
    function GetNfaSet(i : Longint): TNfaSet;
  public
    function Count: integer;
    function GetIndex(aNfaSet: TNfaSet): integer;
    property Items[i : Longint]: TNfaSet read GetNfaSet; Default;
    function Add(ASet: TNfaSet): integer;
  end;

  { TNfaConverter }

  TNfaConverter = class
  private
    fLabelSet: TLabelSet;
    fSetSet: TSetSet;
    procedure MakeLabelSet(aNfa: TNfa);
  public
    procedure Convert(aNfa: TNfa; aDfa: TDfa);
  end;

implementation

{ TSetSet }

function TSetSet.GetNfaSet(i : Longint): TNfaSet;
begin
  Result:=fSetList[i];
end;

function TSetSet.Add(ASet: TNfaSet): integer;
begin
  Result := GetIndex(ASet);
  if Result<0 then
  begin
    fSetList.Add(aSet);
    Result := fSetList.Count-1;
  end;
end;

function TSetSet.Count: integer;
begin
  Result:=fSetList.Count;
end;

function TSetSet.GetIndex(aNfaSet: TNfaSet): integer;
var
  i: integer;
begin
  Result := -1;
  for i := 0 to fSetList.Count-1 do
    if aNfaSet.Equals(fSetList[i]) then
    begin
      Result := i;
      exit;
    end;
end;


{ TNfaSet }

constructor TNfaSet.Create;
begin
  fBits:=TBits.Create;
end;

destructor TNfaSet.Destroy;
begin
  fBits.Free;
end;

function TNfaSet.Equals(Obj: TObject): boolean;
var
  other: TNfaSet;
begin
  other:=Obj as TNfaSet;
  Result:=fBits.Equals(other.fBits);
end;

procedure TNfaSet.Add(nfaState: TNfaState);
begin
  fNfaList.Add(nfaState);
  fBits.SetOn(nfaState.SelfIndex);
end;

procedure TNfaSet.eClosure(aNfa: TNfa);
begin
  TransitTo(aNfa, TLabel.Create(''), self);
end;

function TNfaSet.nonEmpty: boolean;
begin
  Result:=fNfaList.Count>0;
end;

procedure TNfaSet.TransitTo(aNfa: TNfa; ALabel: TLabel; DestSet: TNfaSet);
var
  i,index: integer;
  SrcState: TNfaState;
  DestState: TNfaState;
  List: TNfaTransitionList;
begin
  index := 0;
  while index<fNfaList.Count do
  begin
    SrcState := fNfaList[Index];
    List:=TNfaTransitionList.Create(false);
    SrcState.FindTransitionByLabel(ALabel,list);
    for i := 0 to List.Count-1 do
     begin
       DestState := aNfa.getState(List[i].Dest);
       DestSet.Add(DestState);
     end;
    List.Free;
  end;
end;

{ TNfaConverter }

procedure TNfaConverter.MakeLabelSet(aNfa: TNfa);
var
  list: TLabelList;
  i: integer;
begin
  list:=TLabelList.Create(false);
  aNfa.GetAllLabels(list);
  for i:=0 to list.Count-1 do
     if not list[i].Eps then fLabelSet.Add(list[i]);
  list.Free;
end;

procedure TNfaConverter.Convert(aNfa: TNfa; aDfa: TDfa);
var
  index: integer;
  labelIdx: integer;
  StartSet,SrcSet, DestSet: TNfaSet;
begin
  MakeLabelSet(aNfa);
  StartSet := TNfaSet.Create;
  StartSet.Add(aNfa.getState(aNfa.StartIndex));
  StartSet.eClosure(aNfa);
  fSetSet.Add(StartSet);
  index := 0;
  while index<fSetSet.Count do
  begin
    SrcSet := fSetSet[Index];
    for labelIdx := 0 to fLabelSet.Count-1 do
    begin
      DestSet := TNfaSet.Create;
      SrcSet.TransitTo(aNfa, fLabelSet[labelIdx], DestSet);
      if DestSet.nonEmpty then
      begin
        DestSet.eCLosure(aNfa);
        fSetSet.Add(DestSet);
      end;
    end;
  end;
end;

{ TLabelSet }

function TLabelSet.GetLabel(i : Longint): TLabel;
begin
  Result:=fLabelList[i];
end;

constructor TLabelSet.Create();
begin
  fLabelList := TLabelList.Create();
end;

destructor TLabelSet.Destroy;
begin
  fLabelList.Free;
  inherited Destroy;
end;


function TLabelSet.GetIndex(ALabel: TLabel): integer;
var
  i: integer;
begin
  Result := -1;
  for i := 0 to fLabelList.Count-1 do
    if ALabel.Equals(fLabelList[i]) then
    begin
      Result := i;
      exit;
    end;
end;

function TLabelSet.Count: integer;
begin
  Result:=fLabelList.Count;
end;

function TLabelSet.Add(ALabel: TLabel): integer;
begin
  Result := GetIndex(ALabel);
  if Result<0 then
  begin
    fLabelList.Add(ALabel.Clone);
    Result := fLabelList.Count-1;
  end;
end;

end.

