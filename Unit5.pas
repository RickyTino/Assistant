unit Unit5;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls, IniFiles;

type
  TForm5 = class(TForm)
    RichEdit1: TRichEdit;
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form5: TForm5;
  Root: string;
  DataIni: TIniFile;

implementation

{$R *.dfm}



procedure TForm5.FormClose(Sender: TObject; var Action: TCloseAction);
var
  i: longint;
begin
  with DataIni do begin
    EraseSection('NotePaper');
    WriteInteger('NotePaper', 'Width', Width);
    WriteInteger('NotePaper', 'Height', Height);
    for i := 0 to RichEdit1.Lines.Count - 1 do begin
      WriteString('NotePaper', IntToStr(i), RichEdit1.Lines[i]);
    end;
  end;
end;

procedure TForm5.FormCreate(Sender: TObject);
begin
  Root := ExtractFileDir(Application.ExeName);
  DataIni := TIniFile.Create(Root + '/Savedata.ini');
  Width := DataIni.ReadInteger('NotePaper', 'Width', 400);
  Height := DataIni.ReadInteger('NotePaper', 'Height', 400);
  Left := 800;
  Top := 300;
end;

procedure TForm5.FormShow(Sender: TObject);
var
  i: longint;
  linestr: string;
begin
  i:=0;
  RichEdit1.Lines.Clear;
  while true do begin
    linestr := DataIni.ReadString('NotePaper', IntToStr(i), 'EOF');
    if linestr = 'EOF' then break;
    RichEdit1.Lines.Add(linestr);
    inc(i);
  end;
end;

end.
