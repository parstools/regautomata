unit Dfa;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Fa;

type

  { TDfa }
  TDfa = class(TFa)
  public
    function Clone: TDfa;
    procedure AddState(AFinished: Boolean);
    constructor Create;
  end;

implementation

function TDfa.Clone: TDfa;
begin
  Result := TDfa.Create;
  CloneStates(Result);
end;

procedure TDfa.AddState(AFinished: Boolean);
var
  newState: TState;
begin
  newState := TState.Create(True);
  fStates.Add(newState);
  newState.SelfIndex := fStates.Count-1;
  newState.StateList := fStates;
end;

constructor TDfa.Create;
begin
  inherited Create(false);
end;

end.

