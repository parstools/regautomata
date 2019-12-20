unit Dfa;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fgl;

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
  public
    constructor Create();
    destructor Destroy; override;
    function GetIndex(ALabel: TLabel): integer;
    function Add(ALabel: TLabel): integer;
  end;

implementation

{ TLabelSet }

constructor TLabelSet.Create();
begin
  fLabelList:=TLabelList.Create();
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
  Result:=-1;
  for i:=0 to fLabelList.Count-1 do
     if ALabel.Equals(fLabelList[i]) then
     begin
       Result:=i;
       exit;
     end;
end;

function TLabelSet.Add(ALabel: TLabel): integer;
begin
  Result:=GetIndex(ALabel);
  if Result<0 then
  begin
    fLabelList.Add(ALabel.Clone);
    Result:=fLabelList.Count-1;
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
  other:=Obj as TLabel;
  Result:=other.fC=fC;
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

