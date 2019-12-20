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
  end;

implementation

function TDfa.Clone: TDfa;
begin
  Result := TDfa.Create(false);
  CloneStates(Result);
end;

end.

