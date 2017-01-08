unit Unit7;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.Imaging.pngimage, Vcl.Grids,
  DateUtils, Vcl.StdCtrls, IniFiles;

type

  TForm7 = class(TForm)
    Panel1: TPanel;
    DateTimePicker1: TDateTimePicker;
    ListView1: TListView;
    Label1: TLabel;
    Edit1: TEdit;
    ComboBox1: TComboBox;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    DateTimePicker2: TDateTimePicker;
    DateTimePicker3: TDateTimePicker;
    Button1: TButton;
    DateTimePicker4: TDateTimePicker;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Label5: TLabel;
    Label6: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure DateTimePicker1Change(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure ListView1Click(Sender: TObject);
    procedure Edit1Change(Sender: TObject);
    procedure DateTimePicker2Change(Sender: TObject);
    procedure DateTimePicker3Change(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure RenewList;
    procedure SaveList;
    procedure SaveMonthEvent;
    procedure ReadMonthEvent;
    procedure RenewFlags;
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure ListView1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ListView1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ListView1ColumnClick(Sender: TObject; Column: TListColumn);
    procedure ListView1Compare(Sender: TObject; Item1, Item2: TListItem;
      Data: Integer; var Compare: Integer);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure GetNotification1(var reply: string);
    procedure GetNotification2(var reply: string);
  end;

  TSignCalendar = class
  public
    Cells: Array[1..7, 0..6] of TPanel;
    Img: Array[1..7, 1..6] of TImage;
    DateInt: Array[1..7, 1..6] of longint;
    Left, Top: longint;
    Hight, Width: longint;
    CellHeight, CellWidth: longint;
    constructor Create(l, t, cellh, cellw: longint);
    procedure RenewCalendar;
    procedure CellClick(Sender: TObject);
    procedure CellMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  end;

  TEvent = record
    Event, EventType, StartTime, EndTime: string;
    Checked: boolean;
  end;

  TMonthEvent = Array[1..7, 1..6, 0..100] of TEvent;

const
  WeekDayStr: Array [1..7] of string = ('MON','TUE','WED','THU','FRI','SAT','SUN');
  NormalEvent: string = '过程事件';
  DeadlineEvent: string = '期限事件';
var
  Form7: TForm7;
  Root: string;
  Calendar: TSignCalendar;
  DataIni: TIniFile;
  img: TImage;
  cRow, cCol, tRow, tCol: longint;
  CurDate, ToDate: TDate;
  oriColor: TColor;
  CldSelect, ListSelect: boolean;
  SlcIndex: longint;
  MonthEvent: TMonthEvent;
  meTop: Array[1..7, 1..6] of longint;
  EventDrag: boolean;
  SortCol, SortWay: longint;

implementation

{$R *.dfm}

function MinusTime(a, b: TDateTime): string;
var
  day, hour, minute: longint;
  ret: string;
begin
  minute := MinutesBetween(a, b);
  hour := minute div 60;
  minute := minute mod 60;
  day := hour div 24;
  hour := hour mod 24;
  if day <> 0 then ret := ret + IntToStr(day) + 'day ';
  if hour <> 0 then ret := ret + IntToStr(hour) + 'h ';
  if minute <> 0 then ret := ret + IntToStr(minute) + 'min';
  Exit(ret);
end;

constructor TSignCalendar.Create(l, t, cellh, cellw: longint);
var
  i, j: longint;
begin
  Left := l;
  Top := t;
  CellHeight := Cellh;
  CellWidth := Cellw;
  cRow := 0;
  cCol := 0;
  Form7.Panel1.Height := 6 * cellh + cellh div 2;
  Form7.Panel1.Width := 7 * cellw;
  for i := 1 to 7 do begin
    for j := 0 to 6 do begin
      DateInt[i, j] := 0;
      Cells[i, j] := TPanel.Create(Form7);
      if j = 0 then begin
        with Cells[i, j] do begin
        Parent := Form7;
        ParentBackground := false;
        Left := l + (i - 1) * cellw;
        Top := t;
        Height := cellh div 2;
        width := cellw;
        Caption := WeekDayStr[i];
        end;
      end else begin
        with Cells[i, j] do begin
          Parent := Form7;
          ParentBackground := false;
          Left := l + (i - 1) * cellw;
          Top := t + (j - 1) * cellh + cellh div 2;
          Height := cellh;
          Width := cellw;
          Color := clWhite;
          Font.Size := 11;
          Visible := true;
          OnClick := CellClick;
          OnMouseUp := CellMouseUp;
        end;
        Img[i, j] := TImage.Create(Form7);
        with Img[i, j] do begin
          Parent := Cells[i, j];
          Left := cellw - 10;
          Top := 0;
          Height := cellh;
          Width := cellw;
          Visible := true;
          Stretch := false;
          Picture.LoadFromFile(Root + '/Icon/Transparent.png');
          OnClick := CellClick;
          OnMouseUp := CellMouseUp;
        end;
      end;
    end;
  end;
end;

procedure TSignCalendar.RenewCalendar;
var
  i, j:longint;
  DspDate: TDate;
  Month, Year, Day, FirstWeek: longint;
begin
  DspDate := CurDate;
  Month := MonthOf(DspDate);
  Year := YearOf(DspDate);
  Day := 1;
  for j := 1 to 6 do
    for i := 1 to 7 do
      with Cells[i, j] do begin
        Caption := '';
        Color := clWhite;
        BevelInner := bvNone;
        DateInt[i, j] := 0;
     end;
  for j := 1 to 6 do begin
    for i := 1 to 7 do begin
      if (j = 1) and (i <> DayOfTHeWeek(EncodeDate(Year, Month, Day))) then continue;
      if Day <= DaysInAMonth(Year, Month) then begin
        Cells[i, j].Caption := IntToStr(Day);
        if EncodeDate(Year, Month, Day) = DateOf(Now) then begin
          Cells[i, j].Color := $82FFFF;
          tCol := i;
          tRow := j;
        end;
        DateInt[i, j] := Day;
        inc(Day);
      end;
    end;
  end;
  cRow := 0;
  cCol := 0;
  CldSelect := false;
end;

procedure TSignCalendar.CellClick(Sender: TObject);
var
  img: TImage;
  panel: TPanel;
begin
  if Sender.ClassType = TPanel then begin
    panel := Sender as TPanel;
  end;
  if Sender.ClassType = TImage then begin
    img := Sender as TImage;
    panel := img.Parent as TPanel;
  end;
  if (cCol <> 0) and (cRow <> 0) then begin
    Cells[cCol, cRow].Color := oriColor;
    Cells[cCol, cRow].BevelInner := bvNone;
  end;
  if panel.Caption = '' then begin
    CldSelect := false;
    cCol := 0;
    cRow := 0;
  end else begin
    if (cCol <> 0) and (cRow <> 0) then begin
      Form7.SaveList;
      Form7.SaveMonthEvent;
    end;
    CldSelect := true;
    cCol := (panel.Left - Left) div CellWidth + 1;
    cRow := (panel.Top - Top + CellHeight div 2) div CellHeight;
    CurDate := EncodeDate(YearOf(CurDate), MonthOF(CurDate), StrToInt(panel.Caption));
    oriColor := Cells[cCol, cRow].Color;
    panel.Color := clSkyBlue;
    panel.BevelInner := bvLowered;
    Form7.RenewList;
  end;
end;

procedure TSignCalendar.CellMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
var
  panel: TPanel;
  toRow, toCol: longint;
begin
  if EventDrag then begin

    if Sender.ClassType = TPanel then begin
      panel := Sender as TPanel;
    end;
    if Sender.ClassType = TImage then begin
      panel := (Sender as TImage).Parent as TPanel;
    end;
    toCol := (panel.Left - Left) div CellWidth + 1;
    toRow := (panel.Top - Top + CellHeight div 2) div CellHeight;
    if (toCol = cCol) and (toRow = cRow) then Exit;
    ToDate := EncodeDate(YearOf(CurDate), MonthOf(CurDate), Calendar.DateInt[toCol, toRow]);
    Form7.Button4.Click;
    Form7.Button2.Click;
    EventDrag := false;
  end;
end;

procedure TForm7.Button1Click(Sender: TObject);
var
  i: longint;
begin
  if (not ListSelect) and CldSelect then begin
    with ListView1 do begin
      Items.Add;
      i := Items.Count - 1;
      Items[i].Caption := Edit1.Text;
      Items[i].SubItems.Add(ComboBox1.Text);
      if ComboBox1.Text <> DeadlineEvent then
        Items[i].SubItems.Add(FormatDateTime('HH:mm', DateTimePicker2.Time))
      else
        Items[i].SubItems.Add('');
      Items[i].SubItems.Add(FormatDateTime('HH:mm', DateTimePicker3.Time));
    end;
    Edit1.Text := '';
    SaveList;
    SaveMonthEvent;
  end;
end;

procedure TForm7.Button2Click(Sender: TObject);
begin
  if EventDrag or (ListSelect and CldSelect) then begin
    with ListView1 do begin
      ListSelect := false;
      Items[SlcIndex].Delete;
      Edit1.Text := '';
    end;
  end;
  SaveList;
  SaveMonthEvent;
end;

procedure TForm7.Button3Click(Sender: TObject);
begin
    Button4.Click;
    Button2.Click;
end;

procedure TForm7.Button4Click(Sender: TObject);
var
  Title, Event: string;
  StartTime, EndTime: string;
  toCol, toRow: longint;
  i: longint;
begin
  if EventDrag or (ListSelect and CldSelect) then begin
    if not EventDrag then begin
      ToDate := DateTimePicker4.Date;
      if ToDate = CurDate then Exit;
    end;
    Title := 'Event-' + DateToStr(ToDate);
    i := 0;
    while True do begin
      Event := DataIni.ReadString(Title, 'Event'+IntToStr(i), 'NULL');
      if Event = 'NULL' then break;
      inc(i);
    end;
    with ListView1.Items[SlcIndex] do begin
      DataIni.WriteString(Title, 'Event'+IntToStr(i), Caption);
      DataIni.WriteString(Title, 'Type'+IntToStr(i), SubItems[0]);
      DataIni.WriteString(Title, 'StartTime'+IntToStr(i), SubItems[1]);
      DataIni.WriteString(Title, 'EndTime'+IntToStr(i), SubItems[2]);
      DataIni.WriteBool(Title, 'Checked'+IntToStr(i), Checked);
      ReadMonthEvent;
    end;
  end;
end;

procedure TForm7.ComboBox1Change(Sender: TObject);
begin
  if ListSelect then
    ListView1.Items[SlcIndex].SubItems[0] := ComboBox1.Text;
  if ComboBox1.Text = DeadlineEvent then begin
    Label3.Enabled := false;
    DateTimePicker2.Enabled := false;
    if ListSelect then
      ListView1.Items[SlcIndex].SubItems[1] := '';
  end else begin
    Label3.Enabled := true;
    DateTimePicker2.Enabled := true;
    if ListSelect then
      ListView1.Items[SlcIndex].SubItems[1] := FormatDateTime('HH:mm', DateTimePicker2.Time);
  end;
end;

procedure TForm7.DateTimePicker1Change(Sender: TObject);
begin
  SaveMonthEvent;
  CurDate := DateTimePicker1.Date;
  Calendar.RenewCalendar;
  ReadMonthEvent;
end;

procedure TForm7.DateTimePicker2Change(Sender: TObject);
begin
  if ListSelect then
    ListView1.Items[SlcIndex].SubItems[1] := FormatDateTime('HH:mm', DateTimePicker2.Time);
end;

procedure TForm7.DateTimePicker3Change(Sender: TObject);
begin
  if ListSelect then
    ListView1.Items[SlcIndex].SubItems[2] := FormatDateTime('HH:mm', DateTimePicker3.Time);
end;

procedure TForm7.Edit1Change(Sender: TObject);
begin
  if ListSelect then
    ListView1.Items[SlcIndex].Caption := Edit1.Text;
end;

procedure TForm7.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SaveMonthEvent;
end;

procedure TForm7.FormCreate(Sender: TObject);
var
  a,b,c,d: word;
begin
  Root := ExtractFileDir(Application.ExeName);
  DataIni := TIniFile.Create(Root + '/Savedata.ini');
  Calendar := TSignCalendar.Create(Panel1.Left, Panel1.Top, 40, 50);
  DateTimePicker1.Date := Now;
  CurDate := DateTimePicker1.Date;
  Calendar.RenewCalendar;
  ReadMonthEvent;
  Calendar.CellClick(Calendar.Cells[tCol, tRow]);
  ListView1Click(Self);
  EventDrag := false;
  SortWay := 1;
  Left := 800;
  Top := 300;
end;

procedure TForm7.ListView1Click(Sender: TObject);
var
  i: longint;
begin
  ListSelect := false;
  for i := 0 to ListView1.Items.Count - 1 do begin
    if ListView1.Items[i].Selected then begin
      Edit1.Text := ListView1.Items[i].Caption;
      ComboBox1.Text :=  ListView1.Items[i].SubItems[0];
      ComboBox1Change(Self);
      if ComboBox1.Text <> DeadlineEvent then
        DateTimePicker2.Time := StrToTime(ListView1.Items[i].SubItems[1]);
      DateTimePicker3.Time := StrToTime(ListView1.Items[i].SubItems[2]);
      ListSelect := true;
      SlcIndex := i;
    end;
  end;
  if not ListSelect then begin
    Edit1.Text := '';
    ComboBox1.Text := NormalEvent;
    ComboBox1Change(Self);
    DateTimePicker2.Time := StrToTime('0:00');
    DateTimePicker3.Time := StrToTime('0:00');
  end;
  SaveList;
end;

procedure TForm7.ListView1ColumnClick(Sender: TObject; Column: TListColumn);
begin
  SortCol:=Column.Index;
  if (SortWay=1) then SortWay:=-1 else SortWay:=1;
  (Sender as TCustomListView).AlphaSort;
  ListView1Click(Self);
  SaveList;
  SaveMonthEvent;
end;

procedure TForm7.ListView1Compare(Sender: TObject; Item1, Item2: TListItem;
  Data: Integer; var Compare: Integer);
var
  t: Integer;
begin
  if (SortCol=0) then
  begin
    Compare:=SortWay * CompareText(Item1.Caption,Item2.Caption);
  end else
  begin
    t:=SortCol-1;
    Compare:=SortWay * CompareText(Item1.SubItems[t],Item2.SubItems[t]);
  end;
end;

procedure TForm7.ListView1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  i: longint;
begin
  EventDrag := true;
  for i := 0 to ListView1.Items.Count - 1 do
    if ListView1.Items[i].Selected then
      SlcIndex := i;
end;

procedure TForm7.ListView1MouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  EventDrag := false;
end;

procedure TForm7.RenewList;
var
  i: longint;
begin
  with ListView1 do begin
    Items.Clear;
    for i := 0 to meTop[cCol, cRow] - 1 do begin
      with MonthEvent[cCol, cRow, i] do begin
        Items.Add;
        Items[i].Caption := Event;
        Items[i].SubItems.Add(EventType);
        if EventType <> DeadlineEvent then
          Items[i].SubItems.Add(StartTime)
        else
          Items[i].SubItems.Add('');
        Items[i].SubItems.Add(EndTime);
        Items[i].Checked := Checked;
      end;
    end;
  end;
end;

procedure TForm7.SaveList;
var
  i: longint;
begin
  with ListView1 do begin
    for i := 0 to Items.Count - 1 do begin
      with MonthEvent[cCol, cRow, i] do begin
        Event := Items[i].Caption;
        EventType := Items[i].SubItems[0];
        if EventType <> DeadlineEvent then
          StartTime := Items[i].SubItems[1];
        EndTime := Items[i].SubItems[2];
        Checked := Items[i].Checked;
      end;
    end;
    meTop[cCol, cRow] := Items.Count;
  end;
  RenewFlags;
end;

procedure TForm7.ReadMonthEvent;
var
  i, j, k, Day: longint;
  SlcDate: TDate;
  Title: string;
begin
  for j := 1 to 6 do
    for i := 1 to 7 do
      if Calendar.DateInt[i, j] <> 0 then begin
        Day := Calendar.DateInt[i, j];
        SlcDate := EncodeDate(YearOf(CurDate), MonthOf(CurDate), Day);
        Title := 'Event-' + DateToStr(SlcDate);
        k := 0;
        while true do begin
          with MonthEvent[i, j, k] do begin
            Event := DataIni.ReadString(Title, 'Event' + IntToStr(k), 'NULL');
            if Event = 'NULL' then break;
            EventType := DataIni.ReadString(Title, 'Type' + IntToStr(k), NormalEvent);
            if EventType <> DeadlineEvent then
              StartTime := DataIni.ReadString(Title, 'StartTime' + IntToStr(k), '00:00')
            else
              StartTime := '';
            EndTime := DataIni.ReadString(Title, 'EndTime' + IntToStr(k), '00:00');
            Checked := DataIni.ReadBool(Title, 'Checked'+IntToStr(k), false);
          end;
          inc(k);
        end;
        meTop[i, j] := k;
      end else meTop[i, j] := 0;
  RenewFlags;
end;

procedure TForm7.SaveMonthEvent;
var
  i, j, k, Day: longint;
  SlcDate: TDate;
  Title: string;
begin
  for j := 1 to 6 do
    for i := 1 to 7 do
      if Calendar.DateInt[i, j] <> 0 then begin
        Day := Calendar.DateInt[i, j];
        SlcDate := EncodeDate(YearOf(CurDate), MonthOf(CurDate), Day);
        Title := 'Event-' + DateToStr(SlcDate);
        DataIni.EraseSection(Title);
        for k := 0 to meTop[i, j] - 1 do begin
          with MonthEvent[i, j, k] do begin
            DataIni.WriteString(Title, 'Event'+IntToStr(k), Event);
            DataIni.WriteString(Title, 'Type'+IntToStr(k), EventType);
            DataIni.WriteString(Title, 'StartTime'+IntToStr(k), StartTime);
            DataIni.WriteString(Title, 'EndTime'+IntToStr(k), EndTime);
            DataIni.WriteBool(Title, 'Checked'+IntToStr(k), Checked);
          end;
        end;
      end;
end;

procedure TForm7.RenewFlags;
var
  i, j, k: longint;
  flag: boolean;
begin
  for j := 1 to 6 do
    for i := 1 to 7 do begin
      if meTop[i, j] <> 0 then begin
        flag := true;
        for k := 0 to meTop[i, j] - 1 do
          if not MonthEvent[i, j, k].Checked then flag := false;
        if flag then
          Calendar.Img[i, j].Picture.LoadFromFile(Root + '/Icon/GreenSign.png')
        else
          Calendar.Img[i, j].Picture.LoadFromFile(Root + '/Icon/RedSign.png');
      end else
        Calendar.Img[i, j].Picture.LoadFromFile(Root + '/Icon/Transparent.png');
    end;
end;

procedure TForm7.GetNotification1(var reply: string);
var
  d,di: TDate;
  st, et, minst: TTime;
  sdt, edt: TDateTime;
  i, k, mink: longint;
  Title, Event, EventType : string;
  StartTime, EndTime: string;
  Checked, flag: Boolean;
  Events: Array[0..100] of TEvent;
begin
  d := DateOf(Now);
  flag := false;
  for i := 0 to 30 do begin
    di := IncDay(d, i);
    Title := 'Event-' + DateToStr(di);
    k := 0;
    minst := StrToTime('23:59:59');
    while true do begin
      with Events[k] do begin
        Event := DataIni.ReadString(Title, 'Event' + IntToStr(k), 'NULL');
        if Event = 'NULL' then break;
        EventType := DataIni.ReadString(Title, 'Type' + IntToStr(k), NormalEvent);
        if EventType = DeadlineEvent then begin
          inc(k);
          continue;
        end;
        StartTime := DataIni.ReadString(Title, 'StartTime' + IntToStr(k), '00:00');
        EndTime := DataIni.ReadString(Title, 'EndTime' + IntToStr(k), '00:00');
        Checked := DataIni.ReadBool(Title, 'Checked'+IntToStr(k), false);
        if not Checked then begin
          st := StrToTime(StartTime);
          sdt := st + di;
          et := StrToTime(EndTime);
          edt := et + di;
          if (CompareTime(minst, st) = 1) and (CompareDateTime(edt, Now) >= 0)then begin
            flag := true;
            minst := st;
            mink := k;
          end;
        end;
      end;
      inc(k);
    end;
    if flag then begin
      with Events[mink] do begin
        st := StrToTime(StartTime);
        et := StrToTime(EndTime);
        sdt := st + di;
        edt := et + di;
        if CompareDateTime(sdt, Now) >= 0  then begin
          reply := Event + ' 未开始 剩' + MinusTime(sdt, Now);
          Exit;
        end
        else begin
          reply := Event + ' 进行中 剩' + MinusTime(edt, Now);
          Exit;
        end;
      end;
    end;
  end;
  reply := '';
end;

procedure TForm7.GetNotification2(var reply: string);
var
  d,di: TDate;
  et, minet: TTime;
  edt: TDateTime;
  i, k, mink: longint;
  Title, Event, EventType : string;
  EndTime: string;
  Checked, flag: Boolean;
  Events: Array[0..100] of TEvent;
begin
  d := DateOf(Now);
  flag := false;
  for i := 0 to 30 do begin
    di := IncDay(d, i);
    Title := 'Event-' + DateToStr(di);
    k := 0;
    minet := StrToTime('23:59:59');
    while true do begin
      with Events[k] do begin
        Event := DataIni.ReadString(Title, 'Event' + IntToStr(k), 'NULL');
        if Event = 'NULL' then break;
        EventType := DataIni.ReadString(Title, 'Type' + IntToStr(k), NormalEvent);
        if EventType = NormalEvent then begin
          inc(k);
          continue;
        end;
        EndTime := DataIni.ReadString(Title, 'EndTime' + IntToStr(k), '00:00');
        Checked := DataIni.ReadBool(Title, 'Checked'+IntToStr(k), false);
        if not Checked then begin
          et := StrToTime(EndTime);
          edt := et + di;
          if (CompareTime(minet, et) = 1) and (CompareDateTime(edt, Now) >= 0) then begin
            flag := true;
            minet := et;
            mink := k;
          end;
        end;
      end;
      inc(k);
    end;
    if flag then begin
      with Events[mink] do begin
        et := StrToTime(EndTime);
        edt := et + di;
        reply := Event + ' 剩' + MinusTime(edt, Now);
        Exit;
      end;
    end;
  end;
  reply := '';
end;

end.
