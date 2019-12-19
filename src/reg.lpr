program reg;

uses Nfa;

var
  aNfa,bNfa: TNfa;
begin
  aNfa:=TNfa.Create;
  aNfa.AddStateByLabel('a');
  aNfa.AddStateByLabel('b');
  aNfa.printDot('out1.dot');
  aNfa.printDot('out1back.dot',true);
  aNfa.Check();
  aNfa.MakeQuest;
  aNfa.Check();
  aNfa.printDot('out2.dot',false);
  aNfa.printDot('out2back.dot',true);

  bNfa:=TNfa.Create;
  bNfa.AddStateByLabel('c');
  bNfa.AddStateByLabel('d');

  aNfa.AddParallel(bNfa);
  aNfa.Check();
end.

