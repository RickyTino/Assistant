unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, DateUtils, Vcl.ExtCtrls, IniFiles, ShellAPI,
  Vcl.Menus, GDIPApi, GDIPObj, Vcl.Imaging.pngimage, Vcl.Themes, Vcl.Buttons;

type
  TForm1 = class(TForm)
    Label1: TLabel;
    Button1: TButton;
    Label2: TLabel;
    Timer1: TTimer;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    ListBox1: TListBox;
    Button9: TButton;
    TrayIcon1: TTrayIcon;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    Image1: TImage;
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
    procedure TrayIcon1Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure RenewLook;
    procedure RenewNotification;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure SpeedButton1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  Root: string;
  Version: string;
  MDown: Boolean;
  CursorPos: TPoint;
  ConfigIni: TIniFile;
  CurBackground: string;
  Theme: string;
  Bitmap: TGPBitmap;

implementation

{$R *.dfm}

uses Unit2, Unit3, Unit4, Unit5, Unit6, Unit7;

procedure TForm1.RenewLook;
var
  Background: string;
  AlphaBl: longint;
//  Gender: longint;
  CurTheme: string;
begin
  Background := ConfigIni.ReadString('General', 'Background', '无');
  AlphaBl := ConfigIni.ReadInteger('General', 'AlphaBlendValue', 230);
  //Gender := ConfigIni.ReadInteger('General', 'Gender', -1);
  Theme := ConfigIni.ReadString('General', 'Theme', 'Windows');
  //if Gender <> 0 then Button10.Enabled := false;
  //if Gender = 0 then Button10.Enabled := true;
  if AlphaBl <> AlphaBlendValue then AlphaBlendValue := AlphaBl;
  if Background <> CurBackground then begin
    if Background = '无' then begin
      Image1.Visible := false;
    end else begin
      Image1.Visible := true;
      Image1.Picture.LoadFromFile(Root + '/Background/' + Background + '.png');

    end;
    CurBackground := Background;
  end;
  if Theme <> CurTheme then begin
    TStyleManager.SetStyle(Theme);
    CurTheme := Theme;
  end;
end;

procedure TForm1.RenewNotification;
var
  reply: string;
begin
  with Form1.ListBox1 do begin
    Items.Clear;
    Unit3.Form3.GetNotification(reply);
    if reply <> '' then Items.Add(reply);
    Unit4.Form4.GetNotification(reply);
    if reply <> '' then Items.Add(reply);
    Unit6.Form6.GetNotification(reply);
    if reply <> '' then Items.Add('下一节课：' + reply);
    Unit7.Form7.GetNotification1(reply);
    if reply <> '' then Items.Add('事件：' + reply);
    Unit7.Form7.GetNotification2(reply);
    if reply <> '' then Items.Add('期限：' + reply);
  end;
end;

procedure TForm1.SpeedButton1Click(Sender: TObject);
begin
   With Unit2.Form2 do begin
    Show;
    PageControl1.ActivePage := TabSheet1;
  end;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  Form1.Close;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  Unit3.Form3.Show;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  Unit4.Form4.Show;
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  Unit5.Form5.Show;
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
  Unit6.Form6.Show;
end;

procedure TForm1.Button6Click(Sender: TObject);
begin
  Unit7.Form7.Show;
end;

procedure TForm1.Button7Click(Sender: TObject);
begin
  With Unit2.Form2 do begin
    Show;
    PageControl1.ActivePage := TabSheet2;
  end;
end;

procedure TForm1.Button8Click(Sender: TObject);
begin
  ShowMessage('Programmed By 柴可 - RickyTino ' + #13 +
              'Version: ' + Version + #13 +
              'Class 1504101, Campus of CS, HITWH.');
end;

procedure TForm1.Button9Click(Sender: TObject);
begin
  Self.Visible := false;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  ConfigIni.WriteInteger('General', 'Left', Left);
  ConfigIni.WriteInteger('General', 'Top', Top);
  Application.ProcessMessages;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  TrayIcon1.Icon := Application.Icon;
  TrayIcon1.PopupMenu := PopupMenu1;
  Label1.Caption := DateTimeToStr(Now);
  Root := ExtractFileDir(Application.ExeName);
  ConfigIni := Tinifile.Create(Root + '/Config.ini');
  Left := ConfigIni.ReadInteger('General', 'Left', 800);
  Top := ConfigIni.ReadInteger('General', 'Top', 300);
  Form1.Visible := true;
  Version := ConfigIni.ReadString('System', 'Version', 'Unknown');
  RenewLook;
end;

procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  MDown := true;
  GetCursorPos(CursorPos);
end;

procedure TForm1.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var
  p : TPoint;
begin
  GetCursorPos(P);
  if MDown then begin
    Form1.Left := Form1.Left + (P.X - CursorPos.X);
    Form1.Top := Form1.Top + (P.Y - CursorPos.Y);
    CursorPos := P;
  end;
end;

procedure TForm1.FormMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  MDown := false;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  Label1.Caption := DateTimeToStr(Now);
  RenewNotification;
end;

procedure TForm1.TrayIcon1Click(Sender: TObject);
begin
  Form1.Visible := true;
end;

end.
