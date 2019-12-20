program reg;

uses Nfa, Dfa, NfaConverter, Fa;

var
  aNfa,bNfa: TNfa;
  c1,c2,c3,c4: TNfa;
begin
  aNfa:=TNfa.Create;
  aNfa.AddStateByLabel('a');
  aNfa.AddStateByLabel('b');
  aNfa.Check();
  aNfa.MakeQuest;
  aNfa.Check();

  bNfa:=TNfa.Create;
  bNfa.AddStateByLabel('c');
  bNfa.AddStateByLabel('d');

  aNfa.AddParallel(bNfa);
  aNfa.Check();

  c1:=aNfa.Clone;
  c2:=aNfa.Clone;
  c3:=aNfa.Clone;
  c4:=aNfa.Clone;
  c1.MakePlus;
  c1.printDot('outP.dot');
  c1.MakePlus;
  c1.printDot('outPP.dot');
  c1.MakeQuest;
  c1.printDot('outPQ.dot');
  c1.check;
  c2.MakeQuest;
  c2.printDot('outQ.dot');
  c2.MakePlus;
  c2.printDot('outQP.dot');
  c2.check;
end.

