unit Unit4;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, IniFiles;

type
  TForm4 = class(TForm)
    ListView1: TListView;
    Edit1: TEdit;
    Button1: TButton;
    Button2: TButton;
    Label1: TLabel;
    ComboBox1: TComboBox;
    Button3: TButton;
    procedure FormCreate(Sender: TObject);
    procedure ListView1Click(Sender: TObject);
    procedure Edit1Change(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Button3Click(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure GetNotification(var reply: string);
  end;

var
  Form4: TForm4;
  Root: string;
  SlcIndex: longint;
  SlcFlag: boolean;
  DataIni: TIniFile;

implementation

{$R *.dfm}


procedure TForm4.Button1Click(Sender: TObject);
var
  i: longint;
begin
  if not SlcFlag then begin
    with ListView1 do begin
      Items.Add;
      i := Items.Count - 1;
      Items[i].Caption := Edit1.Text;
      Items[i].SubItems.Add(ComboBox1.Text);
    end;
    Edit1.Text := '';
  end;
end;

procedure TForm4.Button2Click(Sender: TObject);
begin
  if SlcFlag then begin
    with ListView1 do begin
      SlcFlag := false;
      Items[SlcIndex].Delete;
      Edit1.Text := '';
    end;
  end;
end;

procedure TForm4.Button3Click(Sender: TObject);
begin
  Form4.Close();
end;

procedure TForm4.ComboBox1Change(Sender: TObject);
begin
  if SlcFlag then begin
    ListView1.Items[SlcIndex].SubItems.Strings[0] := ComboBox1.Text;
  end;
end;

procedure TForm4.Edit1Change(Sender: TObject);
begin
  if SlcFlag then begin
    ListView1.Items[SlcIndex].Caption := Edit1.Text;
  end;
end;

procedure TForm4.FormClose(Sender: TObject; var Action: TCloseAction);
var
  i: longint;
  note, ntag: string;
  nfinish: boolean;
begin
  DataIni.EraseSection('Memo');
  with ListView1 do begin
    for i := 0 to Items.Count - 1 do begin
      note := Items[i].Caption;
      ntag := Items[i].SubItems.Strings[0];
      nfinish := Items[i].Checked;
      DataIni.WriteString('Memo', 'Note'+IntToStr(i), note);
      DataIni.WriteString('Memo', 'Tag'+IntToStr(i), ntag);
      DataIni.WriteBool('Memo', 'Checked'+IntToStr(i), nfinish);
    end;
    Items.Clear;
  end;
end;

procedure TForm4.FormCreate(Sender: TObject);
var
  i:longint;
begin
    Root := ExtractFileDir(Application.ExeName);
    DataIni := TInifile.Create(Root + '/Savedata.ini');
  with ListView1 do begin
    Columns.Add;
    Column[0].Caption := '事项';
    Column[0].Width := Width-85;
    Column[1].Caption := '标签';
    Column[1].Width := 80;
  end;
  SlcFlag := false;
  Left := 800;
  Top := 300;
end;

procedure TForm4.FormShow(Sender: TObject);
var
  i: longint;
  note, ntag: string;
  nfinish: boolean;
begin
  i:=0;
  while true do begin
    with ListView1 do begin
      note := DataIni.ReadString('Memo', 'Note'+IntToStr(i), '');
      ntag := DataIni.ReadString('Memo', 'Tag'+IntToStr(i), '');
      nfinish := DataIni.ReadBool('Memo', 'Checked'+IntToStr(i), false);
      if (note = '') and (ntag = '') then break;
      Items.Add;
      Items[i].Caption := note;
      Items[i].SubItems.Add(ntag);
      Items[i].Checked := nfinish;
      inc(i);
    end;
  end;
end;

procedure TForm4.ListView1Click(Sender: TObject);
var
  i: longint;
begin
  SlcFlag := false;
  for i := 0 to ListView1.Items.Count - 1 do begin
    if ListView1.Items[i].Selected then begin
      SlcFlag := true;
      SlcIndex := i;
      Edit1.Text := ListView1.Items[i].Caption;
      ComboBox1.Text :=  ListView1.Items[i].SubItems.Strings[0];
    end;
  end;
  if not SlcFlag then begin
    Edit1.Text := '';
  end;
end;

procedure TForm4.GetNotification(var reply: string);
var
  i: longint;
  Checked: longint;
begin
  i := 0;
  while True do begin
    Checked := DataIni.ReadInteger('Memo', 'Checked'+IntToStr(i), 3);
    if Checked = 3 then break;
    if Checked = 0 then begin
      reply := '有未完成的备忘。';
      Exit;
    end;
    inc(i);
  end;
  reply := ''
end;

end.
