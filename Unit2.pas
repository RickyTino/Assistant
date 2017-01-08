unit Unit2;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Themes,
  IniFiles, Vcl.OleCtrls, SHDocVw, MSHtml, ActiveX, RegularExpressions, StrUtils, DateUtils;

type
  TForm2 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Edit1: TEdit;
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    DateTimePicker1: TDateTimePicker;
    ComboBox1: TComboBox;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    ComboBox2: TComboBox;
    Label5: TLabel;
    Label6: TLabel;
    Edit2: TEdit;
    Label7: TLabel;
    ScrollBar1: TScrollBar;
    Label8: TLabel;
    ComboBox3: TComboBox;
    TabSheet4: TTabSheet;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Edit3: TEdit;
    Label12: TLabel;
    Edit4: TEdit;
    Edit5: TEdit;
    WebBrowser1: TWebBrowser;
    Button4: TButton;
    Label13: TLabel;
    procedure FormShow(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure ScrollBar1Change(Sender: TObject);
    procedure Button4Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;
  ConfigIni: TIniFile;
  DataIni: TIniFile;
  Root: string;
  UserName: string;
  Grade: string;
  Gender: longint;              //Male: 1 Female: 0
  BirthDay: TDate;
  Background: string;
  Theme: string;
  AlphaBl: longint;
  ReferenceWeek: longint;
  WeekReference: TDate;
  JWAccount, JWPwd: string;


implementation

{$R *.dfm}

uses Unit1, Unit6;

procedure TForm2.Button1Click(Sender: TObject);
begin
  UserName := Edit1.Text;
  if RadioButton1.Checked then Gender := 1
  else if RadioButton2.Checked then Gender := 0
  else Gender := -1;
  BirthDay := DateTimePicker1.Date;
  Grade := ComboBox1.Text;
  Background := ComboBox2.Text;
  AlphaBl := StrToInt(Edit2.Text);
  if (AlphaBl < 10) then AlphaBl := 10;
  if (AlphaBl > 255) then AlphaBl := 255;
  Unit1.Form1.AlphaBlendValue := AlphaBl;
  Theme := ComboBox3.Text;
  ReferenceWeek := StrToInt(Edit3.Text);
  if ReferenceWeek < 1 then ReferenceWeek := 1;
  if ReferenceWeek > 25 then ReferenceWeek := 25;
  Unit6.ReferenceWeek := ReferenceWeek;
  ReferenceDay := IncDay(Now, - DayOfTheWeek(Now) + 1);
  Unit6.ReferenceDay := ReferenceDay;
  JWAccount := Edit4.Text;
  JWPwd := Edit5.Text;
  ConfigIni.WriteString('General', 'UserName', UserName);
  ConfigIni.WriteInteger('General', 'Gender', Gender);
  ConfigIni.WriteString('General', 'Birthday', DateToStr(BirthDay));
  ConfigIni.WriteString('General', 'Grade', Grade);
  ConfigIni.WriteString('General', 'Background', Background);
  ConfigIni.WriteInteger('General', 'AlphaBlendValue', AlphaBl);
  ConfigIni.WriteString('General', 'Theme', Theme);
  DataIni.WriteInteger('Courses', 'ReferenceWeek', ReferenceWeek);
  DataIni.WriteString('Courses', 'ReferenceDay', DateToStr(ReferenceDay));
  DataIni.WriteString('Courses', 'Account', JWAccount);
  DataIni.WriteString('Courses', 'Password', JWPwd);

  Unit1.Form1.RenewLook;
  Unit6.Form6.RenewWeek;
  //Unit6.Form6.RenewAll;
end;

procedure TForm2.Button2Click(Sender: TObject);
begin
  Form2.Close;
end;

procedure TForm2.Button3Click(Sender: TObject);
begin
  Button1Click(Form2);
  Form2.Close;
end;

procedure TForm2.Button4Click(Sender: TObject);
var
  oleObj:OleVariant;
  match: TMatch;
  matches: TMatchCollection;
  mtext, pat, temp, acc, pwd: string;
  posi, i: longint;
begin
  Button1.Click;
  WebBrowser1.Navigate('http://222.194.15.1:7777/zhxt_bks/xk_login.html');
  while webbrowser1.busy do Application.ProcessMessages;
  while webbrowser1.ReadyState <>READYSTATE_COMPLETE do Application.ProcessMessages;
  doc:=WebBrowser1.Document as IHTMLDocument2;
  if doc=nil then begin
    ShowMessage('错误：无法访问教务系统，请检查网络连接。');
    Exit;
  end;
  acc := DataIni.ReadString('Courses', 'Account', 'NULL');
  pwd := DataIni.ReadString('Courses', 'Password', 'NULL');
  if (acc = 'NULL') and (pwd = 'NULL') then begin
    ShowMessage('错误：未设置教务账号与密码。');
    Exit;
  end;
  oleObj:=doc.all.item('stuid',0) as IHTMLElement2;
  oleObj.Value:=acc;
  oleObj:=doc.all.item('pwd',0) as IHTMLElement2;
  oleObj.Value:=pwd;
  webBrowser1.OleObject.document.getElementsByTagName('input').item(2).click;
  Application.ProcessMessages;
  while webbrowser1.busy do Application.ProcessMessages;
  while webbrowser1.ReadyState <>READYSTATE_COMPLETE do Application.ProcessMessages;
  cookie := doc.cookie;
  Application.ProcessMessages;
  WebBrowser1.Navigate('http://222.194.15.1:7777/pls/wwwbks/xk.CourseView');
  while webbrowser1.busy do Application.ProcessMessages;
  while webbrowser1.ReadyState <>READYSTATE_COMPLETE do Application.ProcessMessages;
  doc:=WebBrowser1.Document as IHTMLDocument2;
  doc.cookie := cookie;
  WebBrowser1.Refresh;
  while webbrowser1.busy do Application.ProcessMessages;
  while webbrowser1.ReadyState <>READYSTATE_COMPLETE do Application.ProcessMessages;
  htmldoc := doc.body.outerhtml;
  if Length(htmldoc) = 0 then begin
    ShowMessage('错误：无法获得教务网站数据。');
    Exit;
  end;
  posi := Pos('上课周次', htmldoc) + 15;
  mtext := MidStr(htmldoc, posi, Length(htmldoc));
  pat := '<P align=center>.*&nbsp;</P></TD>';
  matches := TRegEx.Matches(mtext, pat);
  i := 0;
  CCount := 0;
  for  match  in  matches  do begin
    temp := match.Value;
    temp := StringReplace(temp, '<P align=center>', '', []);
    temp := StringReplace(temp, '&nbsp;</P></TD>', '', []);
    temp := StringReplace(temp, '<FONT color=#ff0000></FONT>', '', []);
    if (i = 0) and (temp = '') then break;
    if i = 8 then begin
      temp := copy(temp, 0, pos('周上', temp)-1);
    end;
    DataIni.WriteString('Course'+IntToStr(CCount), SectionName[i], temp);
    inc(i);
    if i>8 then begin
      i := 0;
      inc(CCount);
    end;
  end;
  DataIni.WriteInteger('Courses', 'Count', CCount);
  Unit6.Form6.ReadSchedule;
  Unit6.Form6.RenewAll;
  ShowMessage('获取成功！');
end;

procedure TForm2.FormCreate(Sender: TObject);
begin
  Root := ExtractFileDir(Application.ExeName);
  ConfigIni := TIniFile.Create(Root + '/Config.ini');
  DataIni := TIniFile.Create(Root + '/Savedata.ini');
  Left := 800;
  Top := 300;
  PageControl1.ActivePage := TabSheet2;
  Label13.Caption := 'Programmed By 柴可 - RickyTino ' + #13 + #13 +
                     'Email: 294970540@qq.com' + #13 + #13 +
                     'Version: ' + Version + #13 + #13 +
                     'Class 1504101, Campus of Computer Science,' + #13 + #13 +
                     'Harbin Institute of Technology at Weihai.' + #13 + #13 +
                     'Special thanks to: @芝草蔷薇 for offering some designing;' + #13 + #13 +
                     '                          @Sgly for Significant Suggestions.  ';
end;

procedure TForm2.FormShow(Sender: TObject);
begin
  //ShowMessage('老子回来了！');        <-看这个逗比
  Username := ConfigIni.ReadString('General', 'UserName', '主人');
  Gender := ConfigIni.ReadInteger('General', 'Gender', -1);
  BirthDay := StrToDate(ConfigIni.ReadString('General', 'Birthday', DateToStr(Now)));
  Grade := ConfigIni.ReadString('General', 'Grade', '大一');
  Background := ConfigIni.ReadString('General', 'Background', 'White');
  Theme := ConfigIni.ReadString('General', 'Theme', 'Windows');
  ReferenceWeek := DataIni.ReadInteger('Courses', 'ReferenceWeek', 1);
  ReferenceDay := StrToDate(DataIni.ReadString('Courses', 'ReferenceDay', DateToStr(Now)));
  JWAccount := DataIni.ReadString('Courses', 'Account', '');
  JWPwd := DataIni.ReadString('Courses', 'Password', '');
  Edit1.Text := Username;
  DateTimePicker1.Date := BirthDay;
  ComboBox1.Text := Grade;
  ComboBox2.Text := Background;
  AlphaBl := Unit1.Form1.AlphaBlendValue;
  Edit2.Text := IntToStr(AlphaBl);
  ComboBox3.Text := Theme;
  Edit3.Text := IntToStr(ReferenceWeek);
  Edit4.Text := JWAccount;
  Edit5.Text := JWPwd;
  if Gender=1 then RadioButton1.Checked := true;
  if Gender=0 then RadioButton2.Checked := true;

end;

procedure TForm2.ScrollBar1Change(Sender: TObject);
begin
  Edit2.Text := IntToStr(ScrollBar1.Position);
end;

end.
