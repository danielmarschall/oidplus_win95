program OIDPLUS;

uses
  Forms,
  Main in 'Main.pas' {Form1},
  SortStrings in 'SortStrings.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
