unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, IniFiles, ComCtrls;

type
  TForm1 = class(TForm)
    TreeView1: TTreeView;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    Label1: TLabel;
    Edit3: TEdit;
    Label3: TLabel;
    Memo1: TMemo;
    Edit4: TEdit;
    Label4: TLabel;
    CheckBox1: TCheckBox;
    ComboBox1: TComboBox;
    Label5: TLabel;
    Edit5: TEdit;
    Label6: TLabel;
    Edit6: TEdit;
    Label7: TLabel;
    ListBox1: TListBox;
    Edit7: TEdit;
    Button1: TButton;
    Button3: TButton;
    Button2: TButton;
    Button4: TButton;
    Edit1: TEdit;
    TabSheet3: TTabSheet;
    Button5: TButton;
    Edit2: TEdit;
    TabSheet4: TTabSheet;
    Button6: TButton;
    Edit8: TEdit;
    Button7: TButton;
    Button8: TButton;
    Edit9: TEdit;
    Label2: TLabel;
    Edit10: TEdit;
    Label8: TLabel;
    Edit11: TEdit;
    Label9: TLabel;
    Edit12: TEdit;
    Label10: TLabel;
    Edit13: TEdit;
    Label11: TLabel;
    Button9: TButton;
    Edit14: TEdit;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    procedure TreeView1Change(Sender: TObject; Node: TTreeNode);
    procedure FormShow(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure CheckBox1Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
    procedure Edit8KeyPress(Sender: TObject; var Key: Char);
    procedure Edit11Change(Sender: TObject);
    procedure ListBox1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Edit7KeyPress(Sender: TObject; var Key: Char);
    procedure Edit2KeyPress(Sender: TObject; var Key: Char);
    procedure Edit1KeyPress(Sender: TObject; var Key: Char);
    procedure TreeView1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    function ShowOID(oid: string; ini: TIniFile; nod: TTreeNode): integer;
    procedure ShowRA(ini: TIniFile; nod: TTreeNode);
    function DBPath: string;
    function GetAsn1Ids(onlyfirst: boolean): string;
    procedure SaveChangesIfRequired;
    procedure ShowError(msg: string);
  end;

var
  Form1: TForm1;

implementation

{$R *.DFM}

uses
  SortStrings;

resourcestring
  TITLE_OID = 'Object Identifiers';
  TITLE_RA = 'Registration Authorities';

procedure Split(Delimiter: string; Str: string; ListOfStrings: TStrings) ;
var
  p: integer;
begin
  ListOfStrings.Clear;
  p := Pos(Delimiter, Str);
  while p > 0 do
  begin
    ListOfStrings.Add(Copy(Str, 1, p-1));
    Delete(Str, 1, p);
    p := Pos(Delimiter, Str);
  end;
  if Str <> '' then ListOfStrings.Add(Str);
end;

function TForm1.ShowOID(oid: string; ini: TIniFile; nod: TTreeNode): integer;
var
  i: integer;
  sectionName: string;
  asn1ids: string;
  sl: TStringList;
begin
  result := 0;
  if oid = 'OID:' then
  begin
    nod := TreeView1.Items.AddChild(nod, TITLE_OID);
  end
  else
  begin
    asn1ids := ini.ReadString(oid, 'asn1id', '');
    if ini.ReadBool(oid, 'draft', false) then
      nod := TreeView1.Items.AddChild(nod, Trim(oid+' '+Copy(asn1ids,1,Pos(',',asn1ids+',')-1))+' [DRAFT]')
    else
      nod := TreeView1.Items.AddChild(nod, Trim(oid+' '+Copy(asn1ids,1,Pos(',',asn1ids+',')-1)));
  end;
  sl := TStringList.Create;
  for i := 1 to ini.ReadInteger(oid, 'delegates', 0) do
  begin
    sectionName := ini.ReadString(oid, 'delegate'+IntToStr(i), '');
    if sectionName = '' then continue;
    sl.Add(sectionName);
    Inc(result);
  end;
  SortSL(sl);
  for i := 0 to sl.Count-1 do
  begin
    sectionName := sl.Strings[i];
    (*result := result + *)ShowOid(sectionName, ini, nod);
  end;
  sl.Free;
  if (oid = 'OID:') or (result < 125) then
    nod.Expand(false);
end;

procedure TForm1.ShowRA(ini: TIniFile; nod: TTreeNode);
var
  i: integer;
  sectionName, personname: string;
  sl: TStringList;
begin
  nod := TreeView1.Items.AddChild(nod, TITLE_RA);
  sl := TStringList.Create;
  for i := 1 to ini.ReadInteger('RA:', 'count', 0) do
  begin
    sectionName := ini.ReadString('RA:', 'ra'+IntToStr(i), '');
    if sectionName = '' then continue;
    personname := ini.ReadString(sectionName, 'name', '');
    sl.Add(Trim(sectionName + ' ' + personname));
  end;
  SortSL(sl);
  for i := 0 to sl.Count-1 do
  begin
    sectionName := sl.Strings[i];
    TreeView1.Items.AddChild(nod, sectionName);
    ComboBox1.Items.Add(Copy(sectionName,1,Pos(' ',sectionName+' ')-1));
  end;
  sl.Free;
  nod.Expand(false);
end;

procedure TForm1.TreeView1Change(Sender: TObject; Node: TTreeNode);
var
  ini: TIniFile;
  txtFile: string;
begin
  SaveChangesIfRequired;

  if Copy(TreeView1.Selected.Text, 1, 4) = 'OID:' then
  begin
    PageControl1.ActivePage := TabSheet1;
    ini := TIniFile.Create(DBPath+'OID.INI');
    try
      Edit4.Text := Copy(TreeView1.Selected.Text, 1, Pos(' ',TreeView1.Selected.Text+' ')-1);
      ListBox1.Items.Clear;
      Split(',', ini.ReadString(Edit4.Text, 'asn1id', ''), ListBox1.Items);
      Edit3.Text := ini.ReadString(Edit4.Text, 'description', '');
      CheckBox1.Checked := ini.ReadBool(Edit4.Text, 'draft', false);
      txtFile := DBPath+ini.ReadString(Edit4.Text, 'information', '');
      if FileExists(txtFile) then
        Memo1.Lines.LoadFromFile(txtFile)
      else
        Memo1.Lines.Clear;
      Memo1.Modified := false;
      ComboBox1.ItemIndex := ComboBox1.Items.IndexOf(ini.ReadString(Edit4.Text, 'ra', ''));
      Edit5.Text := ini.ReadString(Edit4.Text, 'createdate', '');
      Edit6.Text := ini.ReadString(Edit4.Text, 'updatedate', '');
      Edit7.Text := '';
    finally
      ini.Free;
    end;
  end;
  if Copy(TreeView1.Selected.Text, 1, 3) = 'RA:' then
  begin
    PageControl1.ActivePage := TabSheet2;
    ini := TIniFile.Create(DBPath+'RA.INI');
    try
      Edit9.Text := Copy(TreeView1.Selected.Text, 1, Pos(' ',TreeView1.Selected.Text+' ')-1);
      Edit10.Text := ini.ReadString(Edit9.Text, 'createdate', '');
      Edit11.Text := ini.ReadString(Edit9.Text, 'name', '');
      Edit12.Text := ini.ReadString(Edit9.Text, 'email', '');
      Edit13.Text := ini.ReadString(Edit9.Text, 'phone', '');
      Edit14.Text := ini.ReadString(Edit9.Text, 'updatedate', '');
    finally
      ini.Free;
    end;
  end;
  if TreeView1.Selected.Text = TITLE_OID then PageControl1.ActivePage := TabSheet3;
  if TreeView1.Selected.Text = TITLE_RA then PageControl1.ActivePage := TabSheet4;
end;

procedure TForm1.FormShow(Sender: TObject);
var
  nod, raroot: TTreeNode;
  ini: TIniFile;
begin
  ComboBox1.Clear;
  TreeView1.Items.Clear;
  nod := TTreeNode.Create(Treeview1.Items);

  ini := TIniFile.Create(DBPath+'OID.INI');
  try
    ShowOID('OID:', ini, nod);
  finally
    ini.Free;
  end;

  ini := TIniFile.Create(DBPath+'RA.INI');
  try
    ShowRa(ini, nod);
  finally
    ini.Free;
  end;
end;

function Asn1IdValid(asn1id: string): boolean;
var
  i: integer;
begin
  if asn1id = '' then
  begin
    result := false;
    exit;
  end;

  if not (asn1id[1] in ['a'..'z']) then
  begin
    result := false;
    exit;
  end;

  for i := 2 to Length(asn1id) do
  begin
    if not (asn1id[1] in ['a'..'z', 'A'..'Z', '0'..'9', '-']) then
    begin
      result := false;
      exit;
    end;
  end;

  result := true;
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  asn1id: string;
  i: integer;
begin
  asn1id := Edit7.Text;
  if asn1id = '' then exit;
  for i := 0 to ListBox1.Items.Count-1 do
  begin
    if ListBox1.Items.Strings[i] = asn1id then ShowError('Item already exists');
  end;
  if not Asn1IdValid(asn1id) then ShowError('Invalid alphanumeric identifier');
  ListBox1.Items.Add(asn1id);
  TreeView1.Selected.Text := Trim(Edit4.Text + ' ' + GetAsn1Ids(true));
  Edit7.Text := '';
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  if (ListBox1.Items.Count > 0) and ListBox1.Selected[ListBox1.ItemIndex] then
  begin
    ListBox1.Items.Delete(ListBox1.ItemIndex);
  end;
  TreeView1.Selected.Text := Trim(Edit4.Text + ' ' + GetAsn1Ids(true));
end;

function IsPositiveNumber(str: string): boolean;
var
  i: integer;
begin
  if (str = '') then
  begin
    result := false;
    exit;
  end;

  result := true;
  for i := 1 to Length(str) do
  begin
    if not (str[i] in ['0'..'9']) then
    begin
      result := false;
      exit;
    end;
  end;

  if (str[1] = '0') and (str <> '0') then
  begin
    result := false;
    exit;
  end;
end;

procedure TForm1.Button4Click(Sender: TObject);
var
  ini: TIniFile;
  i, di: integer;
  oid, parent_oid, new_value: string;
  nod: TTreeNode;
  candidate: string;
begin
  if PageControl1.ActivePage = TabSheet1 then new_value := Edit1.Text;
  if PageControl1.ActivePage = TabSheet3 then new_value := Edit2.Text;

  new_value := Trim(new_value);
  if new_value = '' then exit;

  if not IsPositiveNumber(new_value) then ShowError('Not a valid number');

  if PageControl1.ActivePage = TabSheet1 then
  begin
    oid := Edit4.Text + '.' + new_value;
    parent_oid := Edit4.Text;
  end
  else
  begin
    oid := 'OID:' + new_value;
    parent_oid := 'OID:';
  end;

  for i := 0 to TreeView1.Selected.Count-1 do
  begin
    candidate := Copy(TreeView1.Selected.Item[i].Text, 1, Pos(' ',TreeView1.Selected.Item[i].Text+' ')-1);
    if oid = candidate then ShowError('Item already exists');
  end;

  if (parent_oid = 'OID:') and (StrToInt(new_value) > 2) then ShowError('Number must not exceed 2');
  if (parent_oid = 'OID:0') and (StrToInt(new_value) > 39) then ShowError('Number must not exceed 39');
  if (parent_oid = 'OID:1') and (StrToInt(new_value) > 39) then ShowError('Number must not exceed 39');

  ini := TIniFile.Create(DBPath+'OID.INI');
  try
    nod := TreeView1.Items.AddChild(TreeView1.Selected, oid);
    ComboBox1.Text := ini.ReadString(parent_oid, 'ra', '');

    di := ini.ReadInteger(parent_oid, 'delegates', 0);
    ini.WriteInteger(parent_oid, 'delegates', di+1);
    ini.WriteString(parent_oid, 'delegate'+IntToStr(di+1), oid);

    ini.WriteString(oid, 'createdate', DateToStr(date));
    ini.WriteString(oid, 'ra', ComboBox1.Text);

    if PageControl1.ActivePage = TabSheet1 then Edit1.Text := '';
    if PageControl1.ActivePage = TabSheet3 then Edit2.Text := '';

    TreeView1.Selected := nod;

    ini.UpdateFile;
  finally
    ini.Free;
  end;

  ShowMessage('Created: ' + oid);
end;

procedure TForm1.Button7Click(Sender: TObject);
var
  ini: TIniFile;
  di: integer;
  nod: TTreeNode;
  sectionName, new_value, candidate: string;
  i: integer;
begin
  ini := TIniFile.Create(DBPath+'RA.INI');
  try
    new_value := Edit8.Text;
    new_value := Trim(new_value);
    if new_value = '' then exit;

    sectionName := 'RA:'+new_value;

    for i := 0 to TreeView1.Selected.Count-1 do
    begin
      candidate := TreeView1.Selected.Item[i].Text;
      if sectionName = candidate then ShowError('Item already exists');
    end;

    di := ini.ReadInteger('RA:', 'count', 0);
    ini.WriteInteger('RA:', 'count', di+1);
    ini.WriteString('RA:', 'ra'+IntToStr(di+1), sectionName);

    nod := TreeView1.Items.AddChild(TreeView1.Selected, sectionName);

    ini.WriteString(sectionName, 'createdate', DateToStr(date));

    Edit8.Text := '';

    TreeView1.Selected := nod;

    ini.WriteString(sectionName, 'createdate', DateToStr(date));

    ini.UpdateFile;
  finally
    ini.Free;
  end;

  ComboBox1.Items.Add(sectionName);

  ShowMessage('Created: ' + sectionName);
end;

procedure TForm1.Button6Click(Sender: TObject);
var
  ini: TIniFile;
  nod: TTreeNode;
  parent_oid, this_oid: string;
  i: integer;
  sl: TStringList;
begin
  if MessageDlg('Are you sure?', mtConfirmation, mbYesNoCancel, 0) <> idYes then exit;

  ini := TIniFile.Create(DBPath+'OID.INI');
  try
    this_oid := Edit4.Text;
    if TreeView1.Selected.Parent.Text = TITLE_OID then
      parent_oid := 'OID:'
    else
      parent_oid := Copy(TreeView1.Selected.Parent.Text, 1, Pos(' ', TreeView1.Selected.Parent.Text+' ')-1);

    nod := TreeView1.Selected;
    TreeView1.Selected := nod.Parent;
    TreeView1.Items.Delete(nod);

    ini.EraseSection(this_oid);

    sl := TStringList.Create;
    ini.ReadSections(sl);
    for i := 0 to sl.Count-1 do
    begin
      if Copy(sl.Strings[i], 1, Length(this_oid)+1) = this_oid+'.' then
      begin
        ini.EraseSection(sl.Strings[i]);
      end;
    end;
    sl.Free;

    for i := 1 to ini.ReadInteger(parent_oid, 'delegates', 0) do
    begin
      if ini.ReadString(parent_oid, 'delegate'+IntToStr(i), '') = this_oid then
      begin
        ini.WriteString(parent_oid, 'delegate'+IntToStr(i), '');
      end;
    end;

    ini.UpdateFile;
  finally
    ini.Free;
  end;
end;

procedure TForm1.Button8Click(Sender: TObject);
var
  ini: TIniFile;
  nod: TTreeNode;
  parent_ra, this_ra: string;
  i: integer;
begin
  if MessageDlg('Are you sure?', mtConfirmation, mbYesNoCancel, 0) <> idYes then exit;

  ini := TIniFile.Create(DBPath+'RA.INI');
  try
    this_ra := Copy(Treeview1.Selected.Text, 1, Pos(' ',Treeview1.Selected.Text+' ')-1);
    if TreeView1.Selected.Parent.Text = TITLE_RA then
      parent_ra := 'RA:'
    else
      parent_ra := Copy(TreeView1.Selected.Parent.Text, 1, Pos(' ', TreeView1.Selected.Parent.Text+' ')-1);

    nod := TreeView1.Selected;
    TreeView1.Selected := nod.Parent;
    TreeView1.Items.Delete(nod);

    ini.EraseSection(this_ra);

    for i := 1 to ini.ReadInteger(parent_ra, 'count', 0) do
    begin
      if ini.ReadString(parent_ra, 'ra'+IntToStr(i), '') = this_ra then
      begin
        ini.WriteString(parent_ra, 'ra'+IntToStr(i), '');
      end;
    end;

    ComboBox1.Items.Delete(ComboBox1.Items.IndexOf(this_ra));

    ini.UpdateFile;
  finally
    ini.Free;
  end;
end;

function RandomStr(len: integer): string;
var
  i: integer;
begin
  result := '';
  for i := 1 to len do
  begin
    result := result + Chr(ord('A') + Random(26));
  end;
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  ini: TIniFile;
  txtFile, asn1s: string;
  modified: boolean;
begin
  // Attention: Do not rely on TreeView1.Selected.Text, because Button2.Click
  // will be called in TreeView1OnChange()!

  ini := TIniFile.Create(DBPath+'OID.INI');
  try
    modified := false;

    if ini.ReadString(Edit4.Text, 'ra', '') <> ComboBox1.Text then
    begin
      modified := true;
      ini.WriteString(Edit4.Text, 'ra', ComboBox1.Text);
    end;

    if ini.ReadString(Edit4.Text, 'description', '') <> Edit3.Text then
    begin
      modified := true;
      ini.WriteString(Edit4.Text, 'description', Edit3.Text);
    end;

    if ini.ReadBool(Edit4.Text, 'draft', false) <> CheckBox1.Checked then
    begin
      modified := true;
      ini.WriteBool(Edit4.Text, 'draft', CheckBox1.Checked);
    end;

    if Memo1.Modified then
    begin
      modified := true;
      if Trim(Memo1.Lines.Text) = '' then
      begin
        txtFile := ini.ReadString(Edit4.Text, 'information', '');
        if FileExists(DBPath+txtFile) then
        begin
          DeleteFile(DBPath+txtFile);
        end;
        if txtFile <> '' then
        begin
          ini.WriteString(Edit4.Text, 'information', '')
        end;
      end
      else
      begin
        txtFile := ini.ReadString(Edit4.Text, 'information', '');
        if txtFile = '' then
        begin
          repeat
            txtFile := RandomStr(8) + '.TXT';
          until not FileExists(DBPath+txtFile);
          ini.WriteString(Edit4.Text, 'information', txtFile);
        end;

        Memo1.Lines.SaveToFile(DBPath+txtFile);
        Memo1.Modified := false;
      end;
    end;

    asn1s := GetAsn1Ids(false);
    if ini.ReadString(Edit4.Text, 'asn1id', '') <> asn1s then
    begin
      modified := true;
      ini.WriteString(Edit4.Text, 'asn1id', asn1s);
    end;

    if modified then
    begin
      ini.WriteString(Edit4.Text, 'updatedate', DateToStr(Date));
      ini.Updatefile;
    end;
  finally
    ini.Free;
  end;
end;

function TForm1.GetAsn1Ids(onlyfirst: boolean): string;
var
  i: integer;
begin
  result := '';
  for i := 0 to ListBox1.Items.Count-1 do
  begin
    if result = '' then
      result := ListBox1.Items.Strings[i]
    else if not onlyfirst then
      result := result + ',' + ListBox1.Items.Strings[i];
  end;
end;

function DirectoryExists(const Directory: string; FollowLink: Boolean = True): Boolean; // Source: Delphi 10.3.3
var
  Code: Cardinal;
  Handle: THandle;
  LastError: Cardinal;
const
  faSymLink = $00000400; // Available on POSIX and Vista and above
  INVALID_FILE_ATTRIBUTES = DWORD($FFFFFFFF);
begin
  Result := False;
  Code := GetFileAttributes(PChar(Directory));

  if Code <> INVALID_FILE_ATTRIBUTES then
  begin
    if faSymLink and Code = 0 then
      Result := faDirectory and Code <> 0
    else
    begin
      if FollowLink then
      begin
        Handle := CreateFile(PChar(Directory), GENERIC_READ, FILE_SHARE_READ, nil,
          OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, 0);
        if Handle <> INVALID_HANDLE_VALUE then
        begin
          CloseHandle(Handle);
          Result := faDirectory and Code <> 0;
        end;
      end
      else if faDirectory and Code <> 0 then
        Result := True
      else
      begin
        Handle := CreateFile(PChar(Directory), GENERIC_READ, FILE_SHARE_READ, nil,
          OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, 0);
        if Handle <> INVALID_HANDLE_VALUE then
        begin
          CloseHandle(Handle);
          Result := False;
        end
        else
          Result := True;
      end;
    end;
  end
  else
  begin
    LastError := GetLastError;
    Result := (LastError <> ERROR_FILE_NOT_FOUND) and
      (LastError <> ERROR_PATH_NOT_FOUND) and
      (LastError <> ERROR_BAD_PATHNAME) and
      (LastError <> ERROR_INVALID_NAME) and
      (LastError <> ERROR_BAD_NETPATH) and
      (LastError <> ERROR_NOT_READY) and
      (LastError <> ERROR_BAD_NET_NAME);
  end;
end;

function TForm1.DBPath: string;
var
  ini: TIniFile;
begin
  ini := TIniFile.Create('.\OIDPLUS.INI');
  try
    if not ini.ValueExists('SETTINGS', 'DATA') then
    begin
      result := 'DB\';
      ini.WriteString('SETTINGS', 'DATA', result);
      ini.UpdateFile;
    end
    else
    begin
      result := ini.ReadString('SETTINGS', 'DATA', 'DB\');
    end;
    if not DirectoryExists(result) then MkDir(result);
    if not DirectoryExists(result) then
    begin
      ShowError('Cannot create database directory '+result);
    end;
  finally
    ini.Free;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  PageControl1.ActivePage := TabSheet3;
  Randomize;
end;

procedure TForm1.SaveChangesIfRequired;
begin
  if PageControl1.ActivePage = TabSheet1 then Button2.Click; // Save changes
  if PageControl1.ActivePage = TabSheet2 then Button9.Click; // Save changes
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  SaveChangesIfRequired;
  CanClose := true;
end;

procedure TForm1.CheckBox1Click(Sender: TObject);
begin
  if CheckBox1.Checked then
    TreeView1.Selected.Text := Trim(Edit4.Text+' '+GetAsn1Ids(true))+' [DRAFT]'
  else
    TreeView1.Selected.Text := Trim(Edit4.Text+' '+GetAsn1Ids(true));
end;

procedure TForm1.ShowError(msg: string);
begin
  MessageDlg(msg, mtError, [mbOk], 0);
  Abort;
end;

procedure TForm1.Button9Click(Sender: TObject);
var
  ini: TIniFile;
  txtFile, asn1s: string;
  modified: boolean;
begin
  // Attention: Do not rely on TreeView1.Selected.Text, because Button9.Click
  // will be called in TreeView1OnChange()!

  ini := TIniFile.Create(DBPath+'RA.INI');
  try
    modified := false;
    if ini.ReadString(Edit9.Text, 'name', '') <> Edit11.Text then
    begin
      modified := true;
      ini.WriteString(Edit9.Text, 'name', Edit11.Text);
    end;
    if ini.ReadString(Edit9.Text, 'email', '') <> Edit12.Text then
    begin
      modified := true;
      ini.WriteString(Edit9.Text, 'email', Edit12.Text);
    end;
    if ini.ReadString(Edit9.Text, 'phone', '') <> Edit13.Text then
    begin
      modified := true;
      ini.WriteString(Edit9.Text, 'phone', Edit13.Text);
    end;
    if modified then
    begin
      ini.WriteString(Edit9.Text, 'updatedate', DateToStr(Date));
      ini.Updatefile;
    end;
  finally
    ini.Free;
  end;
end;

procedure TForm1.Edit8KeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Button7.Click;
    Key := #0;
    Exit;
  end;
  if Key = #8(*backspace*) then exit;
  if Key in ['a'..'z'] then Key := UpCase(Key);
  if not (Key in ['A'..'Z', '-']) then
  begin
    Beep;
    Key := #0;
  end;
end;

procedure TForm1.Edit11Change(Sender: TObject);
begin
  TreeView1.Selected.Text := Trim(Edit9.Text + ' ' + Edit11.Text);
end;

procedure TForm1.ListBox1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  If Key = 46(*DEL*) then
  begin
    Button3.Click;
    Key := 0;
  end;
end;

procedure TForm1.Edit7KeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Button1.Click;
    Key := #0;
  end;
end;

procedure TForm1.Edit2KeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Button5.Click;
    Key := #0;
  end;
end;

procedure TForm1.Edit1KeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Button4.Click;
    Key := #0;
  end;
end;

procedure TForm1.TreeView1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = 46(*DEL*) then
  begin
    if Copy(TreeView1.Selected.Text, 1, 4) = 'OID:' then
    begin
      Button6.Click;
    end
    else if Copy(TreeView1.Selected.Text, 1, 3) = 'RA:' then
    begin
      Button8.Click;
    end
    else
    begin
      Beep;
    end;

    Key := 0;
  end;
end;

end.
