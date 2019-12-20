program reg;

uses Nfa;

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

  aNfa.printDot('out.dot');
  c1:=aNfa.Clone;
  c2:=aNfa.Clone;
  c3:=aNfa.Clone;
  c4:=aNfa.Clone;
  c1.printDot('outc1.dot');
  c1.MakePlus;
{
  c1.printDot('outplus.dot');
  c2.MakeQuest;
  c2.printDot('outquest.dot');
  c3.MakePlus;
  c3.MakeQuest;
  c3.printDot('outPQ.dot');
  c4.MakeQuest;
  c4.MakePlus;
  c4.printDot('outQP.dot');}
end.

