unit Unit6;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.OleCtrls,
  SHDocVw, Vcl.Grids, MSHtml, ActiveX, RegularExpressions, IniFiles, StrUtils, DateUtils;

type
  TForm6 = class(TForm)
    StringGrid1: TStringGrid;
    WebBrowser1: TWebBrowser;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Edit1: TEdit;
    Button4: TButton;
    Button5: TButton;
    Label3: TLabel;

    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure SetGridBasic;
    procedure RenewDates;
    procedure RenewWeek;
    procedure ReadSchedule;
    procedure RenewAll;
    procedure Edit1Change(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure StringGrid1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure GetNotification(var reply: string);
  end;

  TCourse = record
    Name, Restriction, CID, CNo, Attribute, ExamType, CRoom, CTime, CWeek: string;
  end;

const
  SectionName: Array[0..8] of string = ('课程名称', '选课限制', '课程号', '课序号', '课程属性',
                                        '考试类型', '上课地点', '上课时间', '上课周次');

var
  Form6: TForm6;
  Labels: Array[1..7] of TLabel;
  doc:IHTMLDocument2;
  cookie: widestring;
  htmldoc: string;
  DataIni: TIniFile;
  Root: string;
  CCount, ThisWeek, ReferenceWeek, DspWeek: longint;
  ReferenceDay: TDate;
  Courses: Array [0..100] of TCourse;
  ArrGrid: Array [0..7, 0..5] of longint;
  ClassToday: Array[1..5] of string;

implementation

{$R *.dfm}

uses Unit2;


procedure swap(var a, b: longint);
var
  t: longint;
begin
  t:=a;a:=b;b:=t;
end;

procedure DivideString(s: string; var a, b: longint);
var
  p: longint;
begin
  p := pos('-', s);
  if p = 0 then begin
    a := StrToInt(s);
    b := a;
  end;
  a := StrToInt(copy(s, 1, p-1));
  b := StrToInt(copy(s, p+1, length(s)));
end;

procedure TForm6.SetGridBasic;
var
  mRect: TGridRect;
begin
  StringGrid1.Cells[1,0] := 'MON';
  StringGrid1.Cells[2,0] := 'TUE';
  StringGrid1.Cells[3,0] := 'WED';
  StringGrid1.Cells[4,0] := 'THU';
  StringGrid1.Cells[5,0] := 'FRI';
  StringGrid1.Cells[6,0] := 'SAT';
  StringGrid1.Cells[7,0] := 'SUN';
  StringGrid1.Cells[0,1] := '1-2';
  StringGrid1.Cells[0,2] := '3-4';
  StringGrid1.Cells[0,3] := '5-6';
  StringGrid1.Cells[0,4] := '7-8';
  StringGrid1.Cells[0,5] := '9-10';

  mRect.Left := 20;
  mRect.Right := 20;
  mRect.Top := 0;
  mRect.Bottom := 0;
  StringGrid1.Selection := mRect;
end;

procedure TForm6.StringGrid1Click(Sender: TObject);
var
  i: longint;
begin
  with StringGrid1 do begin
    if ArrGrid[Col, Row] <> -1 then begin
      i := ArrGrid[Col, Row];
      with Courses[i] do begin
        ShowMessage('课程名称：' + Name + #13 +
                    '选课限制：' + Restriction + #13 +
                    '课程号：' + CID + #13 +
                    '课序号：' + CNo + #13 +
                    '课程属性：' + Attribute + #13 +
                    '考试类型：' + ExamType + #13 +
                    '上课地点：' + CRoom + #13 +
                    '上课时间：' + CTime + #13 +
                    '上课周次：' + CWeek);
      end;
    end;
  end;
end;

procedure TForm6.StringGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);

var Area:TRect;
begin
  //显示换行的代码
  if (ACol = 0) or (ARow = 0) then exit;
  StringGrid1.Canvas.Font.Assign(StringGrid1.Font);
  with StringGrid1,StringGrid1.Canvas do
  begin
    FillRect(Rect);
    Area:= Rect;
    InflateRect(Area, -2, -2);
    DrawText(Handle, PChar(Cells[ACol, ARow]),Length(Cells[ACol, ARow]), Area, DT_LEFT);//居中
  end;
end;

procedure TForm6.RenewWeek;
var
  DayRef: TDate;
  i, j: longint;
begin
  ReferenceWeek := DataIni.ReadInteger('Courses', 'ReferenceWeek',1);
  ReferenceDay := StrToDate( DataIni.ReadString('Courses', 'ReferenceDay',DateToStr(Now)));
  DayRef := IncDay(Now, - DayOfTheWeek(Now) + 1);
  i := CompareDate(DayRef, ReferenceDay);
  j := DaysBetween(DayRef, ReferenceDay) + 1;
  j := j div 7;
  ThisWeek := ReferenceWeek + j * i;
  Button4.Click;
end;

procedure TForm6.ReadSchedule;
var
  i: longint;
  sect: string;
begin
  RenewWeek;
  DspWeek := ThisWeek;
  i := 0;
  while True do begin
    sect := 'Course' + IntToStr(i);
    with Courses[i] do begin
      Name := DataIni.ReadString(sect, '课程名称', 'NULL');
      if Name = 'NULL' then break;
      Restriction := DataIni.ReadString(sect, '选课限制', '');
      CID := DataIni.ReadString(sect, '课程号', '');
      CNo := DataIni.ReadString(sect, '课序号', '');
      Attribute := DataIni.ReadString(sect, '课程属性', '');
      ExamType := DataIni.ReadString(sect, '考试类型', '');
      CRoom := DataIni.ReadString(sect, '上课地点', '');
      CTime := DataIni.ReadString(sect, '上课时间', '');
      CWeek := DataIni.ReadString(sect, '上课周次', '');
    end;
    inc(i);
  end;
  CCount := i;
end;

procedure TForm6.RenewDates;
var
  dWeek, i, j: longint;
  d,td: TDate;
begin
  dWeek := DspWeek - ReferenceWeek;
  d := IncDay(ReferenceDay, - DayOfTheWeek(ReferenceDay) + 1);
  d := IncWeek(d, dWeek);
  for i := 1 to 7 do begin
    td := IncDay(d,i-1);
    Labels[i].Caption := IntToStr(MonthOf(td)) + '月' + IntToStr(DayOf(td)) + '日';
    if DateToStr(td) = DateToStr(Now) then begin
      Labels[i].Caption := Labels[i].Caption + '(今天)';
      for j := 1 to 5 do
        ClassToday[j] := StringGrid1.Cells[i, j];
    end;
  end;
end;

procedure TForm6.RenewAll;
var
  i, j, COpen, CClose, WDay, DTime, multi: longint;
  flag: boolean;
  cw, ts1, ts2: string;
begin
  for i := 0 to 7 do
    for j := 0 to 5 do
      ArrGrid[i,j] := -1;
  for i := 0 to 7 do
    StringGrid1.Cols[i].Clear;
  for i := 0 to 5 do
    StringGrid1.Rows[i].Clear;

  Edit1.Text := IntToStr(DspWeek);
  for i := 0 to CCount - 1 do begin
    flag := false;
    multi := 0;
    with Courses[i] do begin
      if CWeek = '' then flag := true
      else begin

        for j := 0 to Length(CWeek)+1 do begin
          if (CWeek[j] = ',') or (j = Length(CWeek)+1) then begin
            cw := copy(CWeek, multi + 1, j - multi -1);
            multi := j;
            DivideString(cw, COpen, CClose);
            if (DspWeek >= COpen) and (DspWeek <= CClose) then
              flag := true;
          end;
        end;
      end;
      if flag then begin
        DivideString(CTime, WDay, DTime);
        if length(Name) > 8 then begin
          ts1 := Name + ' ' + CRoom ;
          ts2 := copy(ts1, 1, 8);
          ts1 := copy(ts1, 9, length(ts1)-8);
          StringGrid1.Cells[WDay, DTime] := ts2 + #13 + #10 + ts1;
        end else begin
          StringGrid1.Cells[WDay, DTime] := Name + ' ' + #13 + #10 + CRoom;
        end;
        ArrGrid[WDay, DTime] := i;
      end;
    end;
  end;
  SetGridBasic;
  RenewDates;
end;

procedure TForm6.Button1Click(Sender: TObject);
begin
  with Unit2.Form2 do begin
    Show;
    PageControl1.ActivePage := TabSheet3;
  end;
end;

procedure TForm6.Button2Click(Sender: TObject);
var
  i: longint;
begin
  i := StrToInt(Edit1.Text);
  if i > 1 then begin
    dec(i);
    Edit1.Text := IntToStr(i);
  end;
end;

procedure TForm6.Button3Click(Sender: TObject);
var
  i: longint;
begin
  i := StrToInt(Edit1.Text);

  if i < 25 then begin
    inc(i);
    Edit1.Text := IntToStr(i);
  end;
end;

procedure TForm6.Button4Click(Sender: TObject);
begin
  Edit1.Text := IntToStr(ThisWeek);
end;

procedure TForm6.Edit1Change(Sender: TObject);
var
  w: longint;
begin
  w := StrToInt(Edit1.Text);
  if (w>=1) and (w<=25) then begin
    DspWeek := w;
    RenewAll;
  end;
end;

procedure TForm6.FormCreate(Sender: TObject);
var
  i:longint;
begin
  Root := ExtractFileDir(Application.ExeName);
  DataIni := TIniFile.Create(Root + '/Savedata.ini');
  WebBrowser1.Visible := false;
  StringGrid1.ColWidths[0] := 40;
  StringGrid1.RowHeights[0] := 30;
  SetGridBasic;
  for i := 1 to 7 do begin
    Labels[i] := TLabel.Create(Form6);
    With Labels[i] do begin
      Parent := Form6;
      Font.Size := 11;
      Caption := '12月23日';
      Left := 60 + (i-1)*120;
      Top := 36;
      Visible := true;
    end;
  end;
  Left := 800;
  Top := 300;
  ReadSchedule;
  RenewAll;
end;

procedure TForm6.GetNotification(var reply: string);
var
  ClassTime: Array[1..5] of TTime;
  i: Integer;
begin
  ClassTime[1] := StrToTime('8:00');
  ClassTime[2] := StrToTime('10:05');
  ClassTime[3] := StrToTime('14:00');
  ClassTime[4] := StrToTime('16:05');
  ClassTime[5] := StrToTime('18:40');
  for i := 1 to 5 do begin
    if CompareTime(TimeOf(Now), ClassTime[i]) = -1 then  //-1: <
      if ClassToday[i] <> '' then begin
        reply := ClassToday[i] + ', ' + FormatDateTime('HH:mm', ClassTime[i]);
        Exit;
      end;
  end;
  i := DataIni.ReadInteger('Courses', 'Count', -1);
  if i <> -1 then
    reply := '今天没有课啦。'
  else
    reply := '';
end;

end.
