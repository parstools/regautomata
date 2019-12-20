unit NfaConverter;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fgl, Nfa, Dfa;

type
    { TLabel }

  TLabel = class
  private
    fC: char;
  public
    constructor Create(AC: char);
    function Equals(Obj: TObject): boolean; override;
    function Clone: TLabel;
    function getDot: string;
  end;

  TLabelList = specialize TFPGObjectList<TLabel>;

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

  TNfaSet = class
    procedure Add(nfaState: TNfaState);
    procedure eClosure(aNfa: TNfa);
    function nonEmpty(ALabel: TLabel): boolean;
  end;

  { TSetSet }

  TSetSet = class
  private
    function GetNfaSet(i : Longint): TNfaSet;
  public
    procedure Add(aNfaSet: TNfaSet);
    function Count: integer;
    property Items[i : Longint]: TNfaSet read GetNfaSet; Default;
    procedure AddIfNotExists(ADestSet: TNfaSet);
  end;

  { TNfaConverter }

  TNfaConverter = class
  private
    fLabelSet: TLabelSet;
    fSetSet: TSetSet;
    procedure MakeLableSet(aNfa: TNfa);
  public
    procedure Convert(aNfa: TNfa; aDfa: TDfa);
  end;

implementation

{ TSetSet }

function TSetSet.GetNfaSet(i : Longint): TNfaSet;
begin

end;

procedure TSetSet.Add(aNfaSet: TNfaSet);
begin

end;

function TSetSet.Count: integer;
begin

end;

procedure TSetSet.AddIfNotExists(ADestSet: TNfaSet);
begin

end;

{ TNfaSet }

procedure TNfaSet.Add(nfaState: TNfaState);
begin

end;

procedure TNfaSet.eClosure(aNfa: TNfa);
begin

end;

function TNfaSet.nonEmpty(ALabel: TLabel): boolean;
begin

end;

{ TNfaConverter }

procedure TNfaConverter.MakeLableSet(aNfa: TNfa);
begin

end;

procedure TNfaConverter.Convert(aNfa: TNfa; aDfa: TDfa);
var
  index: integer;
  labelIdx: integer;
  StartSet,SrcSet, DestSet: TNfaSet;
begin
  MakeLableSet(aNfa);
  StartSet := TNfaSet.Create;
  StartSet.Add(aNfa.getState(aNfa.StartIndex));
  StartSet.eClosure(aNfa);
  fSetSet.Add(StartSet);
  index := 0;
  while index<fSetSet.Count do
  begin
    SrcSet := fSetSet[Index];
    for labelIdx := 0 to fLabelSet.Count-1 do
      if SrcSet.nonEmpty(fLabelSet[labelIdx]) then
      begin
        DestSet := TNfaSet.Create;
        DestSet.eCLosure(aNfa);
        fSetSet.AddIfNotExists(DestSet);
      end;
  end;
end;

{ TLabelSet }

function TLabelSet.GetLabel(i : Longint): TLabel;
begin

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

{ TLabel }

constructor TLabel.Create(AC: char);
begin
  FC := AC;
end;

function TLabel.Equals(Obj: TObject): boolean;
var
  other: TLabel;
begin
  other := Obj as TLabel;
  Result := other.fC = fC;
end;


function TLabel.Clone: TLabel;
begin
  Result := TLabel.Create(FC);
end;

function TLabel.getDot: string;
begin
  Result := fC;
end;

end.

