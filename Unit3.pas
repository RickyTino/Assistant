unit Unit3;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls, DateUtils, IniFiles, Math;

type
  TForm3 = class(TForm)
    MonthCalendar1: TMonthCalendar;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Edit1: TEdit;
    Label2: TLabel;
    Edit2: TEdit;
    Label3: TLabel;
    Edit3: TEdit;
    Button1: TButton;
    Button2: TButton;
    GroupBox2: TGroupBox;
    Label4: TLabel;
    GroupBox3: TGroupBox;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    ListBox1: TListBox;
    Button3: TButton;
    procedure MonthCalendar1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure RenewAll;
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure GetNotification(var reply: string);
  end;

var
  Form3: TForm3;
  Root: string;
  DataIni: TIniFile;
  CurDate: TDate;
  count: longint;
  TotalIn, TotalOut: double;
  DayMoney: double;

implementation

{$R *.dfm}

procedure WriteIni(Date: TDate; num: longint; money: double; note: string);
var
  Title: String;
begin
  Title := 'Cashbook-' + DateToStr(Date);
  DataIni.WriteString(Title, 'Money' + IntToStr(num), FormatFloat('0.00',money));
  DataIni.WriteString(Title, 'Note' + IntToStr(num), note);
end;

function ReadIni(Date: TDate; num: longint; var money: double; var note: string): boolean;
var
  Title, moneyStr: string;
begin
  Title := 'Cashbook-' + DateToStr(Date);
  moneyStr := DataIni.ReadString(Title, 'Money' + IntToStr(num), '0.00');
  money := StrToFloat(moneyStr);
  note := DataIni.ReadString(Title, 'Note' + IntToStr(num), '');
  if (money = 0) and (note = '') then exit(false)
  else exit(true);
end;

procedure IncTotal(money: double);
begin
  if money>=0 then
    TotalIn := TotalIn + money
  else
    TotalOut := TotalOut - money;
  DayMoney := DayMoney + money;
end;

procedure DecTotal(money: double);
begin
  if money>=0 then
    TotalIn := TotalIn - money
  else
    TotalOut := TotalOut + money;
  DayMoney := DayMoney - money;
end;

procedure WriteTotal;
var
  Title: string;
begin
  Title := 'Cashbook-' + FormatDateTime('yyyy/MM', CurDate);
  DataIni.WriteString(Title, 'TotalIn', FormatFloat('0.00', TotalIn));
  DataIni.WriteString(Title, 'TotalOut', FormatFloat('0.00', TotalOut));
  DataIni.WriteString(Title, IntToStr(DayOf(CurDate)), FormatFloat('0.00', DayMoney));
end;

procedure ReadTotal;
var
  Title: string;
begin
  Title := 'Cashbook-' + FormatDateTime('yyyy/MM', CurDate);
  TotalIn := StrToFloat(DataIni.ReadString(Title, 'TotalIn', '0.00'));
  TotalOut := StrToFloat(DataIni.ReadString(Title, 'TotalOut', '0.00'));
  DayMoney := StrToFloat(DataIni.ReadString(Title, IntToStr(DayOf(CurDate)), '0.00'));
end;

function Assess: string;
var
  t: double;
begin
  if TotalIn = 0 then t := 0
  else t := (TotalIn - TotalOut) / TotalIn;
  if t >= 0.7 then exit('有钱任性')
  else if t >= 0.5 then exit('资金充裕')
  else if t >= 0.3 then exit('量入为出')
  else if t >= 0.1 then exit('钱包缩水')
  else exit('吃土喝风');
end;

procedure TForm3.RenewAll;
var
  money: double;
  note: string;
begin
  Form3.ListBox1.Clear;
  count := 0;
  while True do begin
    if ReadIni(CurDate, count+1, money, note) then begin
      inc(count);
      if money >= 0 then
        ListBox1.Items.Add('+' + FormatFloat('0.00', money) + '  ' + note)
      else
        ListBox1.Items.Add(FormatFloat('0.00', money) + '  ' + note);
    end else break;
  end;
  ReadTotal;
  if DayMoney>=0 then
    Label4.Caption := '今日总收支：￥+' + FormatFloat('0.00', DayMoney)
  else
    Label4.Caption := '今日总收支：￥' + FormatFloat('0.00', DayMoney);
  Label5.Caption := '总收入 ￥' + FormatFloat('0.00', TotalIn);
  Label6.Caption := '总支出 ￥' + FormatFloat('0.00', TotalOut);
  Label7.Caption := '月结余 ￥' + FormatFloat('0.00', TotalIn - TotalOut);
  Label8.Caption := '评价：' + Assess;
end;

procedure TForm3.Button1Click(Sender: TObject);
var
  money, inm, outm: double;
begin
  if Edit1.Text='' then inm := 0
  else inm := StrToFloat(Edit1.Text);
  if Edit2.Text='' then outm := 0
  else outm := StrToFloat(Edit2.Text);
  if (outm = 0) and (inm = 0) then exit;
  money := StrToFloat(FormatFloat('0.00', inm-outm));
  inc(count);
  WriteIni(CurDate, count, money, Edit3.Text);
  IncTotal(money);
  WriteTotal;
  RenewAll;
  Button2Click(Form3);
end;

procedure TForm3.Button2Click(Sender: TObject);
begin
  Edit1.Text := '';
  Edit2.Text := '';
  Edit3.Text := '';
end;

procedure TForm3.Button3Click(Sender: TObject);
var
  i, tc: longint;
  money: double;
  note, Title: string;
begin
  Title := 'Cashbook-' + DateToStr(CurDate);
  tc := 1;
  for i := 0 to ListBox1.Count-1 do begin
    if ListBox1.Selected[i] then begin
      ListBox1.Items.Delete(i);
      tc := i+1;
      break;
    end;
  end;
  ReadIni(CurDate, tc, money, note);
  DecTotal(money);
  WriteTotal;
  for i := tc+1 to count do begin
    ReadIni(CurDate, i, money, note);
    WriteIni(CurDate, i-1, money, note);
  end;
  DataIni.WriteInteger(Title, 'Money' + IntToStr(count), 0);
  DataIni.WriteString(Title, 'Note' + IntToStr(count), '');
  dec(count);
  RenewAll;
end;

procedure TForm3.FormCreate(Sender: TObject);
begin
  Root := ExtractFileDir(Application.ExeName);
  DataIni := TIniFile.Create(Root + '/Savedata.ini');
  MonthCalendar1.Date := Date;
  MonthCalendar1Click(Form3);
  Left := 800;
  Top := 300;
end;

procedure TForm3.MonthCalendar1Click(Sender: TObject);
var
  i: longint;
  note, Title: string;

begin

  CurDate := MonthCalendar1.Date;
  GroupBox3.Caption := IntToStr(MonthOf(CurDate))+'月收支情况';
  GroupBox2.Caption := IntToStr(DayOf(CurDate))+'日收支明细';
  RenewAll;
end;

procedure TForm3.GetNotification(var reply: string);
var
  Title: string;
  Money: double;
begin
  Title := 'Cashbook-' + FormatDateTime('yyyy/MM', Now);
  reply := '';
  Money := StrToFloat(DataIni.ReadString(Title, IntToStr(DayOf(Now)), '0.00'));
  if Money < 0 then
    reply := '今日已超支。';
end;

end.
