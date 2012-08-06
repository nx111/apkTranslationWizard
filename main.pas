unit Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DB, BufDataset,  FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  StdCtrls, ExtCtrls, Menus, variants, CheckLst, StrUtils, DBGrids, Grids, Process,
  DOM, XMLRead, XMLWrite, typinfo, lhttp, lNet ,CsvDocument;

type
  THTTPHandler = class
  public
    procedure ClientDisconnect(ASocket: TLSocket);
    procedure ClientDoneInput(ASocket: TLHTTPClientSocket);
    procedure ClientError(const Msg: string; aSocket: TLSocket);
    function ClientInput(ASocket: TLHTTPClientSocket; ABuffer: PChar;
      ASize: integer): integer;
  end;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    BtnAddTranslations: TButton;
    btnCreateDictionary: TButton;
    btnDecode: TButton;
    btnEncode: TButton;
    btnGenerateUpdate: TButton;
    btnGoogleTranslate: TButton;
    btnLoadDict: TButton;
    btnLoadFromZipFile: TButton;
    btnReadXml: TButton;
    btnRefreshApkList: TButton;
    btnRefreshPacking: TButton;
    btnSaveDict: TButton;
    btnTranslate: TButton;
    btnTranslateDict: TButton;
    btnWriteXml: TButton;
    btnWriteXML4All: TButton;
    cbOriginalLang: TComboBox;
    cbTranslatedLang: TComboBox;
    chkListForPacking: TCheckListBox;
    chklstApk: TCheckListBox;
    chkReplaceResourceArsc: TCheckBox;
    chkSignApk: TCheckBox;
    chkStringFromValues: TCheckBox;
    dsDictionary: TDatasource;
    dbgData: TDBGrid;
    dbgDict: TDBGrid;
    dsTranslations: TDatasource;
    edtFilter: TEdit;
    ImageBannerDer: TImage;
    ImageBannerDer1: TImage;
    Label2: TLabel;
    Label3: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    lblFilterField: TLabel;
    meAbout: TMemo;
    meLog: TMemo;
    OpenDialog: TOpenDialog;
    pnlBanner: TPanel;
    pnlEncodeBottom: TPanel;
    pnlEncodeMiddle: TPanel;
    pnlEncodeTop: TPanel;
    pbEncode: TProgressBar;
    pnlTranslationsBottom: TPanel;
    pnlTranslations2: TPanel;
    pnlTranslations1: TPanel;
    pnlTranslationsMiddle: TPanel;
    pbTranslations: TProgressBar;
    pnlTranslationsTop: TPanel;
    pbDecode: TProgressBar;
    pnlDecodeTop: TPanel;
    pgMain: TPageControl;
    pnlDecodeMiddle: TPanel;
    pnlDecodeBottom: TPanel;
    PopupUnPacking: TPopupMenu;
    PopupPacking: TPopupMenu;
    SaveDialog: TSaveDialog;
    SelectAll2: TMenuItem;
    SelectAll3: TMenuItem;
    tsAbout: TTabSheet;
    tsLog: TTabSheet;
    tsEncode: TTabSheet;
    tsTranslations: TTabSheet;
    tsDecode: TTabSheet;
    UnselectAll2: TMenuItem;
    UnselectAll3: TMenuItem;
    procedure BtnAddTranslationsClick(Sender: TObject);
    procedure btnCreateDictionaryClick(Sender: TObject);
    procedure btnDecodeClick(Sender: TObject);
    procedure btnEncodeClick(Sender: TObject);
    procedure btnGenerateUpdateClick(Sender: TObject);
    procedure btnGoogleTranslateClick(Sender: TObject);
    procedure btnLoadDictClick(Sender: TObject);
    function LoadFromZipFile(sZipFile: string): boolean;
    procedure btnLoadFromZipFileClick(Sender: TObject);
    procedure btnReadXmlClick(Sender: TObject);
    procedure btnRefreshApkListClick(Sender: TObject);
    procedure btnRefreshPackingClick(Sender: TObject);
    procedure btnTranslateClick(Sender: TObject);
    procedure btnTranslateDictClick(Sender: TObject);
    procedure btnWriteXML4AllClick(Sender: TObject);
    procedure btnWriteXmlClick(Sender: TObject);
    procedure cbTranslatedLangChange(Sender: TObject);
    procedure dbgDataMouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
    procedure dbgDataPrepareCanvas(Sender: TObject; DataCol: integer;
      Column: TColumn; AState: TGridDrawState);
    procedure dbgDataTitleClick(Column: TColumn);
    procedure dsTranslationsDataChange(Sender: TObject; Field: TField);
    procedure edtFilterChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure pnlDecodeBottomClick(Sender: TObject);
    procedure pnlTranslationsMiddleClick(Sender: TObject);
    function SaveDictionary(sFile: string): boolean;
    procedure btnSaveDictClick(Sender: TObject);
    procedure FindAll(const Path: string; Attr: integer; list: TStrings);
    function ReplaceResources(sResourcesDir, sApkFile: string): boolean;
    function ReplaceResourcesArsc(sOriginalApk, sDestinationApk: string): boolean;
    procedure RunAppInMemo(const sApp: string; AMemo: TMemo);
    function GoogleTranslate(Source: string; langpair: string;
      var resultString: string): boolean;
    procedure LoadLanguages;
    procedure LoadCombos;
    function GenerateUpdateZip(sZipFile: string): boolean;
    procedure CopyFolder(SrcFolder, DstFolder: string);
    procedure GetSubDirectories(const directory: string; list: TStrings);
    procedure FormCreate(Sender: TObject);
    procedure SelectAll2Click(Sender: TObject);
    procedure SelectAll3Click(Sender: TObject);
    procedure UnselectAll2Click(Sender: TObject);
    procedure UnselectAll3Click(Sender: TObject);
 private
    MemDtsTranslations: TBufDataset;
    MemDtsDictionary: TBufDataset;
    MemDtsLanguages: TBufDataset;
   public
    { public declarations }
 end;

const
  csOtherDir: string = 'other';
  csModdingDir: string = 'place-apk-here-for-modding';
  csOutputDir: string = 'projects';
  csCompiledDir: string = 'compiled';
  csResourcesDir: string = 'resources';
  csUpdateDir: string = 'update';
  csScriptsDir: string = 'scripts';
  {$if defined(Win32) or defined(Win64)}
  csScriptExt : string = '.bat';
  {$else}
  csScriptExt : string = '.sh';
  {$endif}


var
  frmMain: TfrmMain;
  HttpClient: TLHTTPClient;
  dummy: THTTPHandler;
  slFilesToTranslate: TStringList;
  giActualRecord: integer;
  gsFilterField: string;
  HTTPBuffer, TranslatedString: string;
  HTTPFinished: boolean;

implementation

{$R *.lfm}


{ TfrmMain }

function ApplicationDirectory(): string;
begin
  {$if defined(Win32) or defined(Win64)}
  Result := AppendPathDelim(ExtractFilePath(Application.ExeName));
  {$else}
  Result := AppendPathDelim(AppendPathDelim(GetUserDir) + 'ApkTranslationWizard');
  {$endif}
end;

function HaveLetters(const Str: string): boolean;
var
  i, iCount: integer;
begin
  //  iCount := 0;
  // for i := 1 to length(Str) do
  //  if UTF8CharacterToUnicode (s[i])(Str[i]) then
  // begin
  //   inc(iCount);
  // end;
  //Result := iCount >= 1;
  Result := trim(Str) <> '';
end;

function SortBufDataSet(DataSet: TBufDataSet; const FieldName: string): boolean;
var
  i: integer;
  IndexDefs: TIndexDefs;
  IndexName: string;
  IndexOptions: TIndexOptions;
  Field: TField;
begin
  Result := False;
  Field := DataSet.Fields.FindField(FieldName);
  //If invalid field name, exit.
  if Field = nil then
    Exit;
  //if invalid field type, exit.
  if {(Field is TObjectField) or} (Field is TBlobField) or
    {(Field is TAggregateField) or} (Field is TVariantField) or
    (Field is TBinaryField) then
    Exit;
  //Get IndexDefs and IndexName using RTTI
  if IsPublishedProp(DataSet, 'IndexDefs') then
    IndexDefs := GetObjectProp(DataSet, 'IndexDefs') as TIndexDefs
  else
    Exit;
  if IsPublishedProp(DataSet, 'IndexName') then
    IndexName := GetStrProp(DataSet, 'IndexName')
  else
    Exit;
  //Ensure IndexDefs is up-to-date
  IndexDefs.Update;
  //If an ascending index is already in use,
  //switch to a descending index
  if IndexName = FieldName + '__IdxA' then
  begin
    IndexName := FieldName + '__IdxD';
    IndexOptions := [ixDescending];
  end
  else
  begin
    IndexName := FieldName + '__IdxA';
    IndexOptions := [];
  end;
  //Look for existing index
  for i := 0 to Pred(IndexDefs.Count) do
  begin
    if IndexDefs[i].Name = IndexName then
    begin
      Result := True;
      Break;
    end;  //if
  end; // for
  //If existing index not found, create one
  if not Result then
  begin
    if IndexName = FieldName + '__IdxD' then
      DataSet.AddIndex(IndexName, FieldName, IndexOptions, FieldName)
    else
      DataSet.AddIndex(IndexName, FieldName, IndexOptions);
    Result := True;
  end; // if not
  //Set the index
  SetStrProp(DataSet, 'IndexName', IndexName);
end;

function DelTree(sDirName: string): boolean;
begin
  try
    Result := DeleteDirectory(sDirName, True);
    if Result then
    begin
      Result := RemoveDirUTF8(sDirName);
    end;
  except
    Result := False;
  end;
end;

procedure Split(const aString, Delimiter: string; Results: TStrings);
begin
  Results.CommaText := StringReplace(aString, '\"', '\""', [rfReplaceAll]);
  if Results.Count >= 1 then
  begin
    // delete the last item, if empty
    if Results[Results.Count - 1] = '' then
    begin
      Results.Delete(Results.Count - 1);
    end;
  end;
end;

function FindMatchStr(Strings: TStrings; const SubStr: string): integer;
var
  sValue1, sValue2: ansistring;
begin
  for Result := 0 to Strings.Count - 1 do
  begin
    sValue1 := Utf8ToAnsi(LowerCase(Strings[Result]));
    sValue2 := Utf8ToAnsi(LowerCase(SubStr));
    if AnsiContainsStr(sValue1, sValue2) then
      exit;
  end;
  Result := -1;
end;



function URLEncode(const s: string): string;
const
  NoConversion = ['A' .. 'Z', 'a' .. 'z', '*', '@', '.', '_', '-',
    '/', ':', '=', '?'];
var
  i, idx, len: integer;

  function DigitToHex(Digit: integer): AnsiChar;
  begin
    case Digit of
      0 .. 9:
        Result := AnsiChar(Chr(Digit + Ord('0')));
      10 .. 15:
        Result := AnsiChar(Chr(Digit - 10 + Ord('A')));
      else
        Result := '0';
    end;
  end; // DigitToHex

begin
  len := 0;
  for i := 1 to length(s) do
    if s[i] in NoConversion then
      len := len + 1
    else
      len := len + 3;
  SetLength(Result, len);
  idx := 1;
  for i := 1 to length(s) do
    if s[i] in NoConversion then
    begin
      Result[idx] := s[i];
      idx := idx + 1;
    end
    else
    begin
      Result[idx] := '%';
      Result[idx + 1] := DigitToHex(Ord(s[i]) div 16);
      Result[idx + 2] := DigitToHex(Ord(s[i]) mod 16);
      idx := idx + 3;
    end;
end;

procedure THTTPHandler.ClientError(const Msg: string; aSocket: TLSocket);
begin
  frmMain.meLog.Lines.Add('gTranslate Error: '+Msg);
  HTTPFinished := True;
end;

procedure THTTPHandler.ClientDisconnect(ASocket: TLSocket);
begin
  HTTPFinished := True;
end;

procedure THTTPHandler.ClientDoneInput(ASocket: TLHTTPClientSocket);
begin
  ASocket.Disconnect;
end;

function THTTPHandler.ClientInput(ASocket: TLHTTPClientSocket;
  ABuffer: PChar; ASize: integer): integer;
var
  oldLength: dword;
  status, response: string;
begin
  try
    oldLength := Length(HTTPBuffer);
    setlength(HTTPBuffer, oldLength + ASize);
    move(ABuffer^, HTTPBuffer[oldLength + 1], ASize);
    Result := aSize; // tell the http buffer we read it all
    Result := aSize; // tell the http buffer we read it all
    // tell the http buffer we read it all
    status := Copy(HTTPBuffer, pos('"responseStatus":', HTTPBuffer) +
      18, length(HTTPBuffer));
    status := Copy(status, 0, pos('}', status) - 1);

    if (status = '200') then
    begin // status is OK
      response := Copy(HTTPBuffer, pos('"translatedText":', HTTPBuffer) +
        18, length(HTTPBuffer));
      TranslatedString := Copy(response, 0, pos('"}, "responseDetails"', response) - 1);
    end
    else
    begin // an error occurred
      TranslatedString := '';
    end;

  except
    TranslatedString := '';
  end;
end;

procedure TfrmMain.LoadLanguages;
var
  Reader: TextFile;
  sLine: UTF8String;
  Campos: TStringList;
  i: integer;
begin
  if FileExistsUTF8(ApplicationDirectory + 'Languages.csv') then
  begin
    try
      Campos := TStringList.Create;
      AssignFile(Reader, ApplicationDirectory + 'Languages.csv');
          {$I-}
      Reset(Reader);
      MemDtsLanguages.Close;
      MemDtsLanguages.Open;
      i := 0;
      while not EOF(Reader) do
      begin
        try
          Readln(Reader, sLine);
          Split(sLine, ',', Campos);
          if i > 0 then
          begin
            MemDtsLanguages.Append;
            MemDtsLanguages.FieldByName('Language').AsString := Campos[0];
            MemDtsLanguages.FieldByName('Region').AsString := Campos[1];
            MemDtsLanguages.Post;
          end;
          Inc(i);
        except
          on e: Exception do
            meLog.Lines.Add('Error loading languages (Line ' +
              IntToStr(i) + '): ' + e.Message);
        end;
      end;
    finally
          {$I+}
      CloseFile(Reader);
      Campos.Free;
    end;
  end;
end;

procedure TfrmMain.LoadCombos;
var
  sLang,sLoc: string;
  iOrig, iTrans: integer;
begin
  if not MemDtsLanguages.Active then
    MemDtsLanguages.Open;
  if not MemDtsLanguages.IsEmpty then
  begin
    MemDtsLanguages.First;
    sLang := '';
    sLoc := '';
    cbOriginalLang.Clear;
    cbTranslatedLang.Clear;
    while not MemDtsLanguages.EOF do
    begin
      if LowerCase(sLang) <> (MemDtsLanguages.FieldByName('Language').AsString + '-' + MemDtsLanguages.FieldByName('Region').AsString) then
      begin
        sLang := MemDtsLanguages.FieldByName('Language').AsString + '-' +  MemDtsLanguages.FieldByName('Region').AsString;
        cbOriginalLang.Items.Add(sLang);
        cbTranslatedLang.Items.Add(sLang);
      end;
      MemDtsLanguages.Next;
    end;
    iOrig := cbOriginalLang.Items.IndexOf('en-rGB');
    iTrans := cbTranslatedLang.Items.IndexOf('zh-rCN');
    if iOrig <> -1 then
      cbOriginalLang.ItemIndex := iOrig;
    if iTrans <> -1 then
      cbTranslatedLang.ItemIndex := iTrans;
  end;
end;

function TfrmMain.GoogleTranslate(Source: string; langpair: string;
  var resultString: string): boolean;
begin
  try
    try
      HTTPBuffer := '';
      HTTPClient := TLHTTPClient.Create(self);
      HttpClient.OnDisconnect := @dummy.ClientDisconnect;
      HttpClient.OnDoneInput := @dummy.ClientDoneInput;
      HttpClient.OnError := @dummy.ClientError;
      HttpClient.OnInput := @dummy.ClientInput;
      HTTPClient.AddExtraHeader('Referer: http://www.microsoft.com');
      HTTPClient.AddExtraHeader('UserAgent: IE6.0');
      HTTPClient.Host := 'ajax.googleapis.com';
      HTTPClient.URI := '/ajax/services/language/translate?v=1.0&q=' +
        URLEncode(Source) + '&langpair=' + langpair;
      HTTPClient.Port := 80;
      HTTPClient.Timeout := 30;
      HTTPClient.SendRequest;
      HTTPFinished := False;
      // Wait until OnDoneInput or OnError
      while (not HTTPFinished) do
        HttpClient.CallAction;
      resultString := TranslatedString;
      Result := True;
    except
      Result := False;
    end;
  finally
    HttpClient.Free;
  end;
end;

procedure TfrmMain.RunAppInMemo(const sApp: string; AMemo: TMemo);
var
  AProcess: TProcess;
begin
  try
    try
      AProcess := TProcess.Create(nil);
      AMemo.Lines.Add('Executing: ' + sApp);
      AProcess.CommandLine := sApp;
      AProcess.Options := AProcess.Options + [poWaitOnExit];
      AProcess.ShowWindow := swoHIDE;
      AProcess.Execute;
    except
      on e: Exception do
        AMemo.Lines.Add('ERROR: Executing: ' + sApp + ' (' + e.Message + ')');
    end;
  finally
    AProcess.Free;
  end;
end;


function TfrmMain.GenerateUpdateZip(sZipFile: string): boolean;
begin
  try
    Result := False;
    // Run Script GenerateUpdateZip
    meLog.Lines.Add(DateTimeToStr(now) + ' - Running Script GenerateUpdateZip: ');
    RunAppInMemo(AppendPathDelim('"' + ApplicationDirectory + csScriptsDir) +
      'GenerateUpdateZip' + csScriptExt + '" "' + sZipFile + '"', meLog);
  except
    on e: Exception do
      meLog.Lines.Add('Error in script GenerateUpdateZip, try manually. Error: ' +
        e.Message);
  end;
end;

function TfrmMain.ReplaceResources(sResourcesDir, sApkFile: string): boolean;
begin
  try
    Result := False;
    // Run Script ReplaceResources
    meLog.Lines.Add(DateTimeToStr(now) + ' - Running Script ReplaceResources: ');
    RunAppInMemo(AppendPathDelim('"' + ApplicationDirectory + csScriptsDir) +
      'ReplaceResources' + csScriptExt + '" "' + sResourcesDir +
      '" "' + sApkFile + '"', meLog);
  except
    on e: Exception do
      meLog.Lines.Add('Error in script ReplaceResources, try manually. Error: ' +
        e.Message);
  end;
end;


function TfrmMain.ReplaceResourcesArsc(sOriginalApk, sDestinationApk: string): boolean;
begin
  try
    Result := False;
    // Run Script ReplaceResourcesArsc
    meLog.Lines.Add(DateTimeToStr(now) + ' - Running Script ReplaceResourcesArsc: ');
    RunAppInMemo(AppendPathDelim('"' + ApplicationDirectory + csScriptsDir) +
      'ReplaceResourcesArsc' + csScriptExt + '" "' + sOriginalApk +
      '" "' + sDestinationApk + '"', meLog);
    Result := True;
  except
    on e: Exception do
    begin
      Result := False;
      meLog.Lines.Add('Error in script ReplaceResourcesArsc, try manually. Error: ' +
        e.Message);

    end;
  end;
end;

procedure TfrmMain.FindAll(const Path: string; Attr: integer; list: TStrings);
var
  fr: TSearchRec;
begin
  list.Clear;
  if FindFirstUTF8(Path, Attr, fr) <> 0 then
  begin
    FindCloseUTF8(fr);
    Exit;
  end;
  repeat
    list.Add(fr.Name);
  until FindNextUTF8(fr) <> 0;
  FindCloseUTF8(fr);
end;

procedure TfrmMain.CopyFolder(SrcFolder, DstFolder: string);
var
  SearchRec: TSearchRec;
  Src, Dst: string;

begin
  Src := AppendPathDelim(SrcFolder);
  Dst := AppendPathDelim(DstFolder);
  ForceDirectories(Dst);
  if FindFirstUTF8(Src + '*.*', faAnyFile, SearchRec) = 0 then
    try
      repeat
        with SearchRec do
          if (Name <> '.') and (Name <> '..') then
            if (Attr and faDirectory) > 0 then
              CopyFolder(Src + Name, Dst + Name)
            else if not FileExistsUTF8(Dst + Name) then
              CopyFile(Src + Name, Dst + Name, False);
      until FindNextUTF8(SearchRec) <> 0;
    finally
      FindCloseUTF8(SearchRec);
    end;
end;

procedure TfrmMain.GetSubDirectories(const directory: string; list: TStrings);
var
  fr: TSearchRec;
begin
  list.Clear;
  if FindFirstUTF8(AppendPathDelim(directory) + '*.*', faDirectory, fr) <> 0 then
  begin
    FindCloseUTF8(fr);
    Exit;
  end;
  repeat
    begin
      if ((fr.Attr and faDirectory <> 0) and (fr.Name <> '.') and
        (fr.Name <> '..')) then
        list.Add(AppendPathDelim(directory) + fr.Name);

    end;
  until FindNextUTF8(fr) <> 0;
  FindCloseUTF8(fr);
end;

procedure TfrmMain.FormCreate(Sender: TObject);
var
  Field: TField;
  i: integer;
begin
  try
    Application.title := self.Caption;
    meAbout.Lines.Add('Working Dir: '+AppendPathDelim(ApplicationDirectory()));
    meAbout.Lines.Add('Working ScriptDir: '+AppendPathDelim(ApplicationDirectory()+csScriptsDir));
    meAbout.Lines.Add('Working OtherDir: '+AppendPathDelim(ApplicationDirectory()+csOtherDir));
    meAbout.Lines.Add('Working ResourcesDir: '+AppendPathDelim(ApplicationDirectory()+csResourcesDir));
    meAbout.Lines.Add('Working CompiledDir: '+AppendPathDelim(ApplicationDirectory()+csCompiledDir));
    meAbout.Lines.Add('Working OutputDir: '+AppendPathDelim(ApplicationDirectory()+csOutputDir));
    meAbout.Lines.Add('Working ModdingDir: '+AppendPathDelim(ApplicationDirectory()+csModdingDir));
    slFilesToTranslate := TStringList.Create;
    slFilesToTranslate.Add('strings.xml');
    slFilesToTranslate.Add('arrays.xml');
    slFilesToTranslate.Add('plurals.xml');
    // create directories
    if not DirectoryExistsUTF8(ApplicationDirectory + csOtherDir) then
      CreateDirUTF8(ApplicationDirectory + csOtherDir);
    if not DirectoryExistsUTF8(ApplicationDirectory + csModdingDir) then
      CreateDirUTF8(ApplicationDirectory + csModdingDir);
    if not DirectoryExistsUTF8(ApplicationDirectory + csOutputDir) then
      CreateDirUTF8(ApplicationDirectory + csOutputDir);
    if not DirectoryExistsUTF8(ApplicationDirectory + csCompiledDir) then
      CreateDirUTF8(ApplicationDirectory + csCompiledDir);
    if not DirectoryExistsUTF8(ApplicationDirectory + csResourcesDir) then
      CreateDirUTF8(ApplicationDirectory + csResourcesDir);
    if not DirectoryExistsUTF8(ApplicationDirectory + csUpdateDir) then
      CreateDirUTF8(ApplicationDirectory + csUpdateDir);
    //create datasets
    MemDtsLanguages := TBufDataset.Create(Application);
    MemDtsLanguages.FieldDefs.Add('Language', ftString, 50, True);
    MemDtsLanguages.FieldDefs.Add('Region', ftString, 50, True);
    for i := 0 to MemDtsLanguages.FieldDefs.Count - 1 do
      MemDtsLanguages.FieldDefs[i].CreateField(MemDtsLanguages);
    LoadLanguages;
    LoadCombos;
    MemDtsDictionary := TBufDataset.Create(Application);
    MemDtsDictionary.FieldDefs.Add('ApkName', ftString, 128, True);
    MemDtsDictionary.FieldDefs.Add('FieldName', ftString, 128, True);
    MemDtsDictionary.FieldDefs.Add('OriginalText', ftString, 1048, False);
    MemDtsDictionary.FieldDefs.Add('TranslatedText', ftString, 1048, False);
    for i := 0 to MemDtsDictionary.FieldDefs.Count - 1 do
      MemDtsDictionary.FieldDefs[i].CreateField(MemDtsDictionary);
    MemDtsDictionary.AutoCalcFields := False;
    dsDictionary.DataSet := MemDtsDictionary;
    MemDtsTranslations := TBufDataset.Create(Application);
    MemDtsTranslations.FieldDefs.Add('ApkName', ftString, 128, True);
    MemDtsTranslations.FieldDefs.Add('FieldName', ftString, 128, True);
    MemDtsTranslations.FieldDefs.Add('OriginalText', ftString, 1048, False);
    MemDtsTranslations.FieldDefs.Add('TranslatedText', ftString, 1048, False);
    for i := 0 to MemDtsTranslations.FieldDefs.Count - 1 do
      MemDtsTranslations.FieldDefs[i].CreateField(MemDtsTranslations);
    MemDtsTranslations.AutoCalcFields := False;
    MemDtsTranslations.MaxIndexesCount := 20;
    dsTranslations.DataSet := MemDtsTranslations;
    MemDtsTranslations.AddIndex('PKIndex', 'ApkName;FieldName', [ixPrimary], '');
    btnRefreshApkList.Click;
    btnRefreshPacking.Click;
  except
    on e: Exception do
    begin
      MessageDlg('Can´t create form, error: ' + e.Message, mtError, [mbOK], 0);
    end;
  end;
end;

procedure TfrmMain.SelectAll2Click(Sender: TObject);
var
  i: integer;
begin
  for i := 0 to chkListForPacking.Items.Count - 1 do
    chkListForPacking.Checked[i] := True;
end;

procedure TfrmMain.SelectAll3Click(Sender: TObject);
var
  i: integer;
begin
  for i := 0 to chklstApk.Items.Count - 1 do
    chklstApk.Checked[i] := True;
end;


procedure TfrmMain.UnselectAll2Click(Sender: TObject);
var
  i: integer;
begin
  for i := 0 to chkListForPacking.Items.Count - 1 do
    chkListForPacking.Checked[i] := False;
end;

procedure TfrmMain.UnselectAll3Click(Sender: TObject);
var
  i: integer;
begin
  for i := 0 to chklstApk.Items.Count - 1 do
    chklstApk.Checked[i] := False;
end;


procedure TfrmMain.btnRefreshApkListClick(Sender: TObject);
begin
  chklstApk.Clear;
  FindAll(AppendPathDelim(ApplicationDirectory + csModdingDir) + '*.apk',
    faAnyFile, chklstApk.Items);
end;

procedure TfrmMain.btnDecodeClick(Sender: TObject);
var
  i: integer;
begin
  if (FileExistsUTF8(AppendPathDelim(ApplicationDirectory + csOtherDir) +
    'apktool.jar')) then
  begin
    if TButton(Sender).Name = 'btnDecode' then
      if MessageDlg('Confirmation', 'Are you sure decode the files selected?',
        mtConfirmation, [mbYes, mbNo], 1) = mrNo then
        exit;
    try
      Screen.Cursor := crHourGlass;
      TButton(Sender).Enabled := False;
      meLog.Lines.Add(DateTimeToStr(now) + ' - BEGIN DECODE PROCESS: ');
      // if exists framework-res.apk, preload it
      if FindMatchStr(chklstApk.Items, 'framework-res.apk') >= 0 then
      begin
        meLog.Lines.Add(
          '--Preloading framework-res.apk------------------------------');
        RunAppInMemo(AppendPathDelim(ApplicationDirectory + csScriptsDir) +
          'java' + csScriptExt + ' -jar "' + AppendPathDelim(
          ApplicationDirectory + csOtherDir) + 'apktool.jar" if "' +
          AppendPathDelim(ApplicationDirectory + csModdingDir) + 'framework-res.apk"',
          meLog);
      end;

      // if exists framework-res.apk, preload it
      if FindMatchStr(chklstApk.Items, 'framework-miui-res.apk') >= 0 then
      begin
        meLog.Lines.Add(
          '--Preloading framework-miui-res.apk------------------------------');
        RunAppInMemo(AppendPathDelim(ApplicationDirectory + csScriptsDir) +
          'java' + csScriptExt + ' -jar "' + AppendPathDelim(
          ApplicationDirectory + csOtherDir) + 'apktool.jar" if "' +
          AppendPathDelim(ApplicationDirectory + csModdingDir) + 'framework-miui-res.apk"',
          meLog);
      end;

      pbDecode.Position := 0;
      pbDecode.Max := chklstApk.Count;
      for i := 0 to chklstApk.Count - 1 do
      begin

        if chklstApk.Checked[i] then
        begin
          DelTree(AppendPathDelim(ApplicationDirectory + csOutputDir) +
            chklstApk.Items[i]);
          meLog.Lines.Add('--' + chklstApk.Items[i] +
            '------------------------------');
          RunAppInMemo(AppendPathDelim(ApplicationDirectory + csScriptsDir) +
            'java' + csScriptExt + ' -jar "' +
            AppendPathDelim(ApplicationDirectory + csOtherDir) +
            'apktool.jar" d "' + AppendPathDelim(ApplicationDirectory + csModdingDir) +
            chklstApk.Items[i] + '" "' + AppendPathDelim(
            ApplicationDirectory + csOutputDir) + chklstApk.Items[i] +
            '"', meLog);
            if not DirectoryExistsUTF8(AppendPathDelim(AppendPathDelim(ApplicationDirectory + csOutputDir)+chklstApk.Items[i])) then
            begin
              // log the error
              meLog.Lines.add('---  ' + chklstApk.Items[i] +
                ' have some ERROR on decode, you must try manually. -------');

          end
        end;
        pbDecode.StepIt;
        Application.ProcessMessages;
      end;
    finally
      btnRefreshPacking.Click;
      meLog.Lines.Add(DateTimeToStr(now) + ' - END ENCODE PROCESS');
      TButton(Sender).Enabled := True;
      Screen.Cursor := crDefault;
    end;
  end
  else
    MessageDlg('The apktool.jar not exists in ' + ApplicationDirectory +
      csOtherDir, mtError, [mbOK], 0);

end;

procedure TfrmMain.btnEncodeClick(Sender: TObject);
var
  i: integer;
  sOriginalApk, sDestinationApk, sResourcesDir: string;
begin
  if (FileExistsUTF8(AppendPathDelim(ApplicationDirectory + csOtherDir) +
    'apktool.jar')) then
  begin
    if TButton(Sender).Name = 'btnEncode' then
      if MessageDlg('Confirmation', 'Are you sure encode the files selected?',
        mtConfirmation, [mbYes, mbNo], 1) = mrNo then
        exit;

    try
      TButton(Sender).Enabled := False;
      meLog.Lines.Add(DateTimeToStr(now) + ' - BEGIN ENCODE PROCESS: ');
      pbEncode.Position := 0;
      pbEncode.Max := chkListForPacking.Count;
      for i := 0 to chkListForPacking.Count - 1 do
      begin

        if chkListForPacking.Checked[i] then
        begin

          Melog.Lines.Add('--' + chkListForPacking.Items[i] +
            '------------------------------');

          DeleteFile(AppendPathDelim(ApplicationDirectory + csCompiledDir) +
            'unsigned-' + chkListForPacking.Items[i]);

          DeleteFile(AppendPathDelim(ApplicationDirectory + csCompiledDir) +
            chkListForPacking.Items[i]);
          RunAppInMemo(AppendPathDelim(ApplicationDirectory + csScriptsDir) +
            'java' + csScriptExt + ' -jar "' +
            AppendPathDelim(ApplicationDirectory + csOtherDir) +
            'apktool.jar" b -f "' + AppendPathDelim(ApplicationDirectory +
            csOutputDir) + chkListForPacking.Items[i] + '" "' +
            AppendPathDelim(ApplicationDirectory + csCompiledDir) +
            'unsigned-' + chkListForPacking.Items[i] + '"', meLog);
          sDestinationApk := AppendPathDelim(ApplicationDirectory +
            csCompiledDir) + 'unsigned-' + chkListForPacking.Items[i];

          if not (FileExistsUTF8(sDestinationApk)) then
          begin
            // log the command
            meLog.Lines.add('---  ' + chkListForPacking.Items[i] +
              ' have some ERROR on encode, you must try manually. -------');

          end
          else
          begin
            if chkReplaceResourceArsc.Checked then
            begin
              // delete if exists de output file
              DeleteFile(AppendPathDelim(ApplicationDirectory +
                csCompiledDir) + chkListForPacking.Items[i]);
              CopyFile(AppendPathDelim(ApplicationDirectory +
                csModdingDir) + chkListForPacking.Items[i],
                AppendPathDelim(ApplicationDirectory + csCompiledDir) +
                chkListForPacking.Items[i],
                False);

              sDestinationApk :=
                AppendPathDelim(ApplicationDirectory + csCompiledDir) +
                'unsigned-' + chkListForPacking.Items[i];

              sOriginalApk :=
                AppendPathDelim(ApplicationDirectory + csCompiledDir) +
                chkListForPacking.Items[i];

              if (FileExistsUTF8(sDestinationApk)) and
                (FileExistsUTF8(sOriginalApk)) then
              begin
                if ReplaceResourcesArsc(sDestinationApk, sOriginalApk) then
                begin
                  meLog.Lines.Add(
                    '--- New resources.arsc into Original APK OK ----------'
                    );
                end
                else
                begin
                  meLog.Lines.Add(
                    '--- ERROR Cant copy New resources.arsc into Original APK----------');
                end;

              end;
              // AfterEncode Event
              // Run Script AfterEncode
              meLog.Lines.Add(DateTimeToStr(now) +
                ' - Running Script AfterEncode: ');
              RunAppInMemo('"' + AppendPathDelim(ApplicationDirectory +
                csScriptsDir) + 'AfterEncode' + csScriptExt + '"', meLog);
              // copy the images... Resources from translated pictures or original lang
              sResourcesDir :=
                AppendPathDelim(AppendPathDelim(ApplicationDirectory +
                csResourcesDir) + chkListForPacking.Items[i]) + 'res';
              if DirectoryExists(sResourcesDir) then
              begin
                if ReplaceResources(sResourcesDir, sOriginalApk) then
                  meLog.Lines.Add(
                    '--- New resources into Original APK OK ----------')
                else
                begin
                  meLog.Lines.add(
                    '--- ERROR Cant copy New resources into Original APK----------');
                end;

              end;

            end;

          end;

          if chkSignApk.Checked then
          begin
            RunAppInMemo(AppendPathDelim(ApplicationDirectory +
              csScriptsDir) + 'java' + csScriptExt + ' -jar "' +
              AppendPathDelim(ApplicationDirectory + csOtherDir) +
              'signapk.jar" -w testkey.x509.pem testkey.pk8 "' +
              AppendPathDelim(ApplicationDirectory + csCompiledDir) +
              'unsigned-' + chkListForPacking.Items[i] + '" "' +
              AppendPathDelim(ApplicationDirectory + csCompiledDir) +
              chkListForPacking.Items[i] + '"', meLog);
            DeleteFile(AppendPathDelim(ApplicationDirectory +
              csCompiledDir) + 'unsigned-' + chkListForPacking.Items[i]);
          end;

        end;
        pbEncode.StepIt;
        Application.ProcessMessages;
      end;



    finally
      meLog.Lines.Add(DateTimeToStr(now) + ' - END ENCODE PROCESS. ');
      TButton(Sender).Enabled := True;
    end;

  end

  else
    MessageDlg('The apktool.jar not exists in ' + ApplicationDirectory +
      csOtherDir, mtError, [mbOK], 0);

end;

procedure TfrmMain.btnGenerateUpdateClick(Sender: TObject);
var
  sZipFile: string;
begin
  try
    btnGenerateUpdate.Enabled := False;
    Screen.Cursor := crHourGlass;
    if SaveDialog.Execute then
    begin
      sZipFile := SaveDialog.FileName;
      GenerateUpdateZip(sZipFile);
    end;
  finally
    btnGenerateUpdate.Enabled := True;
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMain.btnGoogleTranslateClick(Sender: TObject);
var
  sValue: string;
begin
  if not MemDtsTranslations.IsEmpty then
  begin
    if MessageDlg('Confirmation', 'Are you sure encode the files selected?',
      mtConfirmation, [mbNo, mbYes], 1) = mrYes then
      try
        btnGoogleTranslate.Enabled := False;
        MemDtsTranslations.First;
        while not MemDtsTranslations.EOF do
        begin
          try
            if trim(MemDtsTranslations.FieldByName('TranslatedText')
              .AsWideString) = '' then
            begin
              if googleTranslate(
                MemDtsTranslations.FieldByName('OriginalText').AsWideString,
                LowerCase(cbOriginalLang.Text) + '|' +
                LowerCase(cbTranslatedLang.Text), sValue) then
              begin
                MemDtsTranslations.Edit;
                MemDtsTranslations.FieldByName('TranslatedText').AsWideString :=
                  sValue;
                MemDtsTranslations.Post;
                Application.ProcessMessages;
              end;
              // else // error
              // ShowMessage('Error: ' + sRes);
            end;
          finally
            MemDtsTranslations.Next;
          end;
        end;
      finally
        btnGoogleTranslate.Enabled := True;
      end;
  end;
end;



procedure TfrmMain.btnCreateDictionaryClick(Sender: TObject);
var
  XMLDocument: TXMLDocument;
  Resources: TDOMNode; // Root Node
  i, j, h, k, l, iPosLang: integer;
  sName, sNameItem, sValue, sXmlFile, sAPKName: UTF8String;
  slDir, slLocLang: TStringList;
begin
  begin
    try
      btnCreateDictionary.Enabled := False;
      Screen.Cursor := crHourGlass;
      XMLDocument := TXMLDocument.Create;
      begin
        meLog.Lines.Add('--------CREATE DICTIONARY FROM XML--------');
        slDir := TStringList.Create;
        slLocLang := TStringList.Create;
        GetSubDirectories(ApplicationDirectory + csOutputDir,
          slDir);
        if MemDtsTranslations.IsEmpty then
          btnReadXml.Click;
        MemDtsTranslations.DisableControls;
        try
          begin
            for i := 0 to slDir.Count - 1 do
            begin
              for j := 0 to slFilesToTranslate.Count - 1 do
              begin
                // translated
                if FileExistsUTF8(
                  AppendPathDelim(AppendPathDelim(AppendPathDelim(slDir[i]) + 'res') +
                  'values-' + cbTranslatedLang.Text) +
                  slFilesToTranslate[j]) then
                  sXmlFile := AppendPathDelim(AppendPathDelim(
                    AppendPathDelim(slDir[i]) + 'res') + 'values-' +
                    cbTranslatedLang.Text) + slFilesToTranslate[j]
                else
                begin
                  // search in localizated languages
                  GetSubDirectories(AppendPathDelim(AppendPathDelim(slDir[i]) + 'res'),
                    slLocLang);
                  iPosLang :=
                    FindMatchStr(slLocLang, AppendPathDelim(
                    AppendPathDelim(slDir[i]) + 'res') + 'values-' +
                    cbTranslatedLang.Text);
                  if iPosLang >= 0 then
                  begin
                    sXmlFile :=
                      AppendPathDelim(slLocLang[iPosLang]) + slFilesToTranslate[j];
                  end
                  else
                    sXmlFile :=
                      AppendPathDelim(AppendPathDelim(slDir[i] + 'res') + 'values') +
                      slFilesToTranslate[j];
                end;
                sAPKName := ExtractFileName(slDir[i]);
                if FileExistsUTF8(sXmlFile) then
                begin
                  ReadXMLFile(XMLDocument, sXmlFile);
                  //XMLDocument.Encoding := 'UTF-8';
                  Resources := XMLDocument.DocumentElement;
                  // strings.xml
                  if slFilesToTranslate[j] = 'strings.xml' then
                  begin
                    for h := 0 to Resources.ChildNodes.Count - 1 do
                      if Resources.ChildNodes[h].HasAttributes then
                      begin
                        try
                          l := Resources.ChildNodes[h].ChildNodes.Count - 1;
                          try
                            sName :=
                              UTF8Encode(
                              Resources.ChildNodes[h].Attributes.Item[0].NodeValue);
                          except
                            sName := UTF8Encode('');
                          end;
                          if l = 0 then
                            try
                              sValue :=
                                UTF8Encode(
                                Resources.ChildNodes[h].TextContent)
                            except
                              sValue := UTF8Encode('');
                            end

                          else
                          begin
                            if Resources.ChildNodes[h].HasChildNodes then
                              try
                                sValue :=
                                  UTF8Encode(
                                  Resources.ChildNodes[h].ChildNodes[l].NodeValue)
                              except
                                sValue := UTF8Encode('');
                              end
                            else
                              sValue := UTF8Encode(Resources.ChildNodes[h].NodeValue);
                          end;

                          // search apkname + fieldname
                          if MemDtsTranslations.Locate('APkName;FieldName',
                            VarArrayOf([sAPKName, sName]), []) then
                          begin
                            MemDtsTranslations.Edit;
                            MemDtsTranslations.FieldByName('TranslatedText').AsString :=
                              sValue;
                            MemDtsTranslations.Post;
                          end

                        except

                        end;

                      end;
                  end;
                  // Plurals
                  if slFilesToTranslate[j] = 'plurals.xml' then
                  begin
                    for h := 0 to Resources.ChildNodes.Count - 1 do
                      if Resources.ChildNodes[h].HasAttributes then
                      begin
                        try
                          for k :=
                            0 to Resources.ChildNodes[h].ChildNodes.Count - 1 do
                          begin
                            sNameItem := '';
                            if Resources.ChildNodes[h].ChildNodes[k].HasAttributes
                            then
                            begin
                              sName :=
                                UTF8Encode(
                                Resources.ChildNodes[h].Attributes.Item[0].NodeValue);
                              sNameItem :=
                                UTF8Encode(
                                Resources.ChildNodes[h].ChildNodes[
                                k].Attributes.Item[0].NodeValue);
                              try
                                sValue :=
                                  UTF8Encode(
                                  Resources.ChildNodes[h].ChildNodes[
                                  k].TextContent);
                              except
                                sValue := UTF8Encode('');
                              end;
                            end;

                            // search apkname + fieldname
                            if (trim(sNameItem) <> '') then
                              if MemDtsTranslations.Locate('APkName;FieldName',
                                VarArrayOf(
                                [sAPKName, sName + '-' + sNameItem]), []) then
                              begin
                                if trim(
                                  MemDtsTranslations.FieldByName(
                                  'TranslatedText').AsString) = '' then
                                begin
                                  MemDtsTranslations.Edit;
                                  MemDtsTranslations.FieldByName(
                                    'TranslatedText').AsString := sValue;
                                  MemDtsTranslations.Post;
                                end;
                              end;
                          end;

                        except

                        end;

                      end;
                  end;
                  // arrays
                  if slFilesToTranslate[j] = 'arrays.xml' then
                  begin
                    for h := 0 to Resources.ChildNodes.Count - 1 do
                      if (Resources.ChildNodes[h].NodeName = 'string-array') and
                        (Resources.ChildNodes[h].HasAttributes) then
                      begin
                        try
                          for k :=
                            0 to Resources.ChildNodes[h].ChildNodes.Count - 1 do
                          begin
                            sName :=
                              UTF8Encode(
                              Resources.ChildNodes[h].Attributes.Item[0].NodeValue);
                            sNameItem := sName + '-string-array-item' + IntToStr(k);
                            try
                              sValue :=
                                UTF8Encode(
                                Resources.ChildNodes[h].ChildNodes[
                                k].TextContent);
                            except
                              sValue := UTF8Encode('');
                            end;
                            // search apkname + fieldname
                            if (trim(sNameItem) <> '') then
                              // search apkname + fieldname
                              if (trim(sNameItem) <> '') then
                                if MemDtsTranslations.Locate(
                                  'APkName;FieldName', VarArrayOf(
                                  [sAPKName, sName + '-' + sNameItem]), []) then
                                begin
                                  if trim(
                                    MemDtsTranslations.FieldByName(
                                    'TranslatedText').AsString) = '' then
                                  begin
                                    MemDtsTranslations.Edit;
                                    MemDtsTranslations.FieldByName(
                                      'TranslatedText').AsString := sValue;
                                    MemDtsTranslations.Post;
                                  end;
                                end;
                          end;
                        except
                        end;
                      end;
                  end;
                end;
              end;
            end;
          end;
        finally
          slDir.Free;
          slLocLang.Free;
        end;
        MemDtsTranslations.EnableControls;
      end;
    finally
      XMLDocument.Free;
      btnCreateDictionary.Enabled := True;
      Screen.Cursor := crDefault;
    end;
  end;
end;

procedure TfrmMain.BtnAddTranslationsClick(Sender: TObject);
var
  sAPKName, sOriginalText, sFieldName: WideString;
  iAddCount, iUpdatedCount: integer;
  Bookmark: TBookmarkStr;
begin
  if MessageDlg('Confirmation',
    'Sure to add the missing translations in the dictionary?',
    mtConfirmation, [mbYes, mbNo], 1) = mrYes then
  begin
    try
      btnSaveDict.Enabled := False;
      if not MemDtsDictionary.Active then
        MemDtsDictionary.Active := True;
      if not MemDtsTranslations.Active then
        MemDtsTranslations.Active := True;
      iAddCount := 0;
      iUpdatedCount := 0;
      try
        BtnAddTranslations.Enabled := False;
        Screen.Cursor := crHourGlass;
        Bookmark := MemDtsTranslations.Bookmark;
        MemDtsTranslations.DisableControls;
        MemDtsTranslations.Filtered := False;
        MemDtsDictionary.DisableControls;
        MemDtsTranslations.First;
        while not MemDtsTranslations.EOF do
        begin
          sAPKName := MemDtsTranslations.FieldByName('ApkName').AsString;
          sFieldName := MemDtsTranslations.FieldByName('FieldName').AsString;
          sOriginalText := MemDtsTranslations.FieldByName('OriginalText').AsString;
          // search apkname + fieldname
          if not MemDtsDictionary.Locate('APkName;FieldName',
            VarArrayOf([sAPKName, sFieldName]), []) then
          begin
            if (trim(MemDtsTranslations.FieldByName('TranslatedText').AsString) <>
              '') then
            begin
              MemDtsDictionary.Append;
              MemDtsDictionary.FieldByName('ApkName').AsString := sAPKName;
              MemDtsDictionary.FieldByName('FieldName').AsString := sFieldName;
              MemDtsDictionary.FieldByName('OriginalText').AsString := sOriginalText;
              MemDtsDictionary.FieldByName('TranslatedText').AsString :=
                MemDtsTranslations.FieldByName('TranslatedText').AsString;
              MemDtsDictionary.Post;
              Inc(iAddCount);
            end;
          end
          else if MemDtsDictionary.FieldByName('TranslatedText').AsString <>
            MemDtsTranslations.FieldByName('TranslatedText').AsString then
          begin
            MemDtsDictionary.Edit;
            MemDtsDictionary.FieldByName('TranslatedText').AsString :=
              MemDtsTranslations.FieldByName('TranslatedText').AsString;
            MemDtsDictionary.Post;
            Inc(iUpdatedCount);
          end;
          MemDtsTranslations.Next;
        end;
      finally
        MemDtsTranslations.Bookmark := Bookmark;
        //edtFilterChange(nil);
        MemDtsDictionary.First;
        MemDtsTranslations.EnableControls;
        MemDtsDictionary.EnableControls;
        BtnAddTranslations.Enabled := True;
        Screen.Cursor := crDefault;
        MessageDlg(IntToStr(iAddCount) +
          ' translations have been added to the dictionary.' +
          #13#10 + IntToStr(iUpdatedCount) +
          ' translations have been updated to the dictionary.',
          mtInformation, [mbOK], 0);
        if MessageDlg('Confirmation', 'Do you want save the dictionary?',
          mtConfirmation, [mbYes, mbNo], 1) = mrYes then
        begin
          btnSaveDictClick(nil);
        end;
      end;
    finally
      btnSaveDict.Enabled := True;
    end;
  end;
end;

procedure TfrmMain.btnLoadDictClick(Sender: TObject);
var
  Reader: TextFile;
  sLine: UTF8String;
  i: integer;
  FRow,FCol:integer;
  FileStream: TFileStream;
  FParser: TCSVParser;
begin

  if FileExistsUTF8(ApplicationDirectory + 'Dictionary_' + cbOriginalLang.Text +
     '_' + cbTranslatedLang.Text + '.csv') then
  begin
    try
      FileStream := TFileStream.Create( ApplicationDirectory + 'Dictionary_' +
        cbOriginalLang.Text + '_' + cbTranslatedLang.Text + '.csv',
        fmOpenRead or fmShareDenyNone);
      FParser := TCSVParser.Create;
      FParser.Delimiter := ',';
      FParser.QuoteChar := '"';
      FParser.SetSource(FileStream);
          {$I-}
      MemDtsDictionary.Close;
      MemDtsDictionary.Open;
      MemDtsDictionary.DisableControls;
      i := 0;
      while FParser.ParseNextCell do
      begin
        try
          begin
            FRow:=FParser.CurrentRow;
            if FRow <> i then  begin
               i:=FRow;
               if i > 0 then
                  MemDtsDictionary.Append;
            end;
            FCol:=FParser.CurrentCol;
            if i > 0 then begin
               if FCol = 0 then
                  MemDtsDictionary.FieldByName('ApkName').Value := FParser.CurrentCellText;
               if FCol = 1 then
                  MemDtsDictionary.FieldByName('FieldName').Value := FParser.CurrentCellText;
               if FCol = 2 then
                  MemDtsDictionary.FieldByName('OriginalText')
                          .AsString := FParser.CurrentCellText;
               if FCol = 3 then
                  MemDtsDictionary.FieldByName('TranslatedText')
                          .AsString := FParser.CurrentCellText;
               if FCol = 3 then
                  MemDtsDictionary.Post;
            end;
            end;
        except
          on e: Exception do
            meLog.Lines.Add('Error loading dictionary (Line ' +
              IntToStr(i) + '): ' + e.Message);
        end;
      end;
      FileStream.Free;
      MemDtsDictionary.First;
      MemDtsDictionary.EnableControls;
      if TButton(Sender).Name = 'btnLoadDict' then
      begin
        MessageDlg('The Dictonary has been loaded', mtInformation, [mbOK], 0);
      end;
    finally
          {$I+}
    end;
  end;
end;


function TfrmMain.LoadFromZipFile(sZipFile: string): boolean;
begin
  try
    Result := False;
    // Run Script LoadFromZipFile
    meLog.Lines.Add(DateTimeToStr(now) + ' - Running Script LoadFromZipFile: ');
    RunAppInMemo(AppendPathDelim('"' + ApplicationDirectory + csScriptsDir) +
      'LoadFromZipFile' + csScriptExt + '" "' + sZipFile + '"', meLog);
  except
    on e: Exception do
      meLog.Lines.Add('Error in script LoadFromZipFile, try manually. Error: ' +
        e.Message);
  end;
end;


procedure TfrmMain.btnLoadFromZipFileClick(Sender: TObject);
var
  sZipFile: string;
begin
  try
    btnLoadFromZipFile.Enabled := False;
    Screen.Cursor := crHourGlass;
    if OpenDialog.Execute then
    begin
      sZipFile := OpenDialog.FileName;
      LoadFromZipFile(sZipFile);
    end;
  finally
    btnLoadFromZipFile.Enabled := True;
    Screen.Cursor := crDefault;
    btnRefreshApkList.Click;
    SelectAll2.Click;
  end;

end;

procedure TfrmMain.btnReadXmlClick(Sender: TObject);
var
  XMLDocument: TXMLDocument;
  Resources: TDOMNode; // Root Node
  i, j, h, k, l, iPosLang: integer;
  sName, sValue, sXmlFile, sAPKName, sNameItem, sLangSource: string;
  slDir, slLocLang: TStringList;

begin
  try
    meLog.Lines.Add(DateTimeToStr(now) + ' - BEGIN READXML PROCESS: ');
    XMLDocument := TXMLDocument.Create;
    btnReadXml.Enabled := False;
    Screen.Cursor := crHourGlass;
    slDir := TStringList.Create;
    slLocLang := TStringList.Create;
    GetSubDirectories(ApplicationDirectory + csOutputDir,
      slDir);
    MemDtsTranslations.DisableControls;
    pbTranslations.Position := 0;
    pbTranslations.Max := slDir.Count;
    MemDtsTranslations.Close;
    MemDtsTranslations.Open;
    //MemDtsTranslations.Clear(false);

    if chkStringFromValues.Checked then
      sLangSource := ''
    else
      sLangSource := '-' + LowerCase(cbOriginalLang.Text);

    try
      for i := 0 to slDir.Count - 1 do
      begin
        for j := 0 to slFilesToTranslate.Count - 1 do
        begin
          if FileExistsUTF8(AppendPathDelim(
            AppendPathDelim(AppendPathDelim(slDir[i]) + 'res') +
            'values' + sLangSource) + slFilesToTranslate[j]) then
            sXmlFile := AppendPathDelim(AppendPathDelim(
              AppendPathDelim(slDir[i]) + 'res') + 'values' + sLangSource) +
              slFilesToTranslate[j]
          else
          begin
            // search in localizated languages
            GetSubDirectories(AppendPathDelim(AppendPathDelim(slDir[i]) + 'res'),
              slLocLang);
            iPosLang := FindMatchStr(slLocLang,
              AppendPathDelim(AppendPathDelim(slDir[i]) + 'res') +
              'values-' + LowerCase(cbOriginalLang.Text));
            if iPosLang >= 0 then
            begin
              sXmlFile := AppendPathDelim(slLocLang[iPosLang]) +
                slFilesToTranslate[j];
            end
            else
              sXmlFile := AppendPathDelim(AppendPathDelim(slDir[i]) +
                'res') + 'values' + slFilesToTranslate[j];

          end;

          sAPKName := ExtractFileName(slDir[i]);
          if FileExistsUTF8(sXmlFile) then
          begin
            sName := '';
            ReadXMLFile(XMLDocument, sXmlFile);
            XMLDocument.Encoding := 'UTF-8';
            Resources := XMLDocument.DocumentElement;
            // strings.xml
            if slFilesToTranslate[j] = 'strings.xml' then
            begin
              sName := '';
              for h := 0 to Resources.ChildNodes.Count - 1 do
                if Resources.ChildNodes[h].HasAttributes then
                begin
                  try
                    l := Resources.ChildNodes[h].ChildNodes.Count - 1;
                    sName :=
                      UTF8Encode(Resources.ChildNodes[h].Attributes.Item[0].NodeValue);
                    if l = 0 then
                      sValue :=
                        UTF8Encode(Resources.ChildNodes[h].TextContent)
                    else
                    begin
                      if Resources.ChildNodes[h].HasChildNodes then
                        sValue :=
                          UTF8Encode(Resources.ChildNodes[h].ChildNodes[l].NodeValue)
                      else
                        sValue := UTF8Encode(Resources.ChildNodes[h].NodeValue);
                    end;

                    if (trim(sName) <> '') and (HaveLetters(sValue)) then
                    begin
                      MemDtsTranslations.Append;
                      MemDtsTranslations.FieldByName('ApkName').AsString :=
                        sAPKName;
                      MemDtsTranslations.FieldByName('FieldName').AsString :=
                        sName;
                      MemDtsTranslations.FieldByName('OriginalText').AsString :=
                        sValue;
                      MemDtsTranslations.Post;
                    end;
                  except
                    on e: Exception do
                    begin
                      meLog.Lines.Add('Error: ' + sXmlFile +
                        ': ' + 'The xml parser have a error on field ' +
                        sName + ': ' + e.Message);
                    end;
                  end;
                end;
            end;
            // Plurals
            if slFilesToTranslate[j] = 'plurals.xml' then
            begin
              // plurals
              for h := 0 to Resources.ChildNodes.Count - 1 do
                if Resources.ChildNodes[h].HasAttributes then
                begin
                  // item
                  try
                    for k :=
                      0 to Resources.ChildNodes[h].ChildNodes.Count - 1 do
                    begin
                      sNameItem := '';
                      if Resources.ChildNodes[h].ChildNodes[k].HasAttributes
                      then
                      begin
                        sName :=
                          UTF8Encode(
                          Resources.ChildNodes[h].Attributes.Item[0].NodeValue);
                        sNameItem :=
                          UTF8Encode(
                          Resources.ChildNodes[h].ChildNodes[
                          k].Attributes.Item[0].NodeValue);
                        sValue :=
                          UTF8Encode(
                          Resources.ChildNodes[h].ChildNodes[k].TextContent);
                      end;
                      if (trim(sNameItem) <> '') then
                      begin
                        MemDtsTranslations.Append;
                        MemDtsTranslations.FieldByName('ApkName').AsString :=
                          sAPKName;
                        MemDtsTranslations.FieldByName('FieldName').AsString :=
                          sName + '-' + sNameItem;
                        MemDtsTranslations.FieldByName('OriginalText').AsString :=
                          sValue;
                        MemDtsTranslations.Post;
                      end;
                    end;
                  except
                    on e: Exception do
                    begin
                      meLog.Lines.Add('Error: ' + sXmlFile + ': ' +
                        'The xml parser have a error on field ' +
                        sName + ': ' + e.Message);
                    end;
                  end;
                end;
            end;
            // arrays
            if slFilesToTranslate[j] = 'arrays.xml' then
            begin
              for h := 0 to Resources.ChildNodes.Count - 1 do
                if (Resources.ChildNodes[h].NodeName = 'string-array') and
                  (Resources.ChildNodes[h].HasAttributes) then
                begin
                  try
                    for k :=
                      0 to Resources.ChildNodes[h].ChildNodes.Count - 1 do
                    begin
                      sName :=
                        UTF8Encode(Resources.ChildNodes[h].Attributes.Item[0].NodeValue);
                      sNameItem := sName + '-string-array-item' + IntToStr(k);
                      try
                        sValue :=
                          UTF8Encode(Resources.ChildNodes[h].ChildNodes[k].TextContent);
                      except
                        sValue := UTF8Encode('');
                      end;
                      // search apkname + fieldname
                      if (trim(sNameItem) <> '') then
                      begin
                        MemDtsTranslations.Append;
                        MemDtsTranslations.FieldByName('ApkName').AsString :=
                          sAPKName;
                        MemDtsTranslations.FieldByName('FieldName').AsString :=
                          sName + '-' + sNameItem;
                        MemDtsTranslations.FieldByName('OriginalText').AsString :=
                          sValue;
                        MemDtsTranslations.Post;
                      end;
                    end;
                  except
                    on e: Exception do
                    begin
                      meLog.Lines.Add('Error: ' + sXmlFile + ': ' +
                        'The xml parser have a error on field ' +
                        sName + ': ' + e.Message);
                    end;
                  end;
                end;
            end;
          end;
        end;
        pbTranslations.StepIt;
      end;
    except
      on e: Exception do
      begin
        meLog.Lines.add('ERROR: ' + sXmlFile + ': ' +
          'The xml parser have a error: ' + e.Message);
      end;
    end
  finally
    meLog.Lines.Add(DateTimeToStr(now) + ' - END READXML PROCESS. ');
    XMLDocument.Free;
    slDir.Free;
    slLocLang.Free;
    MemDtsTranslations.EnableControls;
    btnReadXml.Enabled := True;
    Screen.Cursor := crDefault;
  end;
end;


procedure TfrmMain.btnRefreshPackingClick(Sender: TObject);
var
  slDir: TStringList;
  i: integer;
begin
  try
    slDir := TStringList.Create;
    chkListForPacking.Clear;
    GetSubDirectories(ApplicationDirectory + csOutputDir,
      slDir);
    for i := 0 to slDir.Count - 1 do
    begin
      chkListForPacking.Items.Add(ExtractFileName(slDir[i]));
    end;

  finally
    slDir.Free;
  end;
end;

procedure TfrmMain.btnTranslateClick(Sender: TObject);
var
  sValue: string;
begin
  if MessageDlg('Confirmation', 'Want to translate using google?',
    mtConfirmation, [mbYes, mbNo], 1) = mrYes then
  begin
    if not MemDtsTranslations.IsEmpty then
    begin
      try
        btnTranslate.Enabled := False;
        if trim(MemDtsTranslations.FieldByName('TranslatedText').AsWideString)
          = '' then
          if GoogleTranslate(MemDtsTranslations.FieldByName('OriginalText')
            .AsWideString, LowerCase(cbOriginalLang.Text) + '|' +
            LowerCase(cbTranslatedLang.Text), sValue) then
          begin
            MemDtsTranslations.Edit;
            MemDtsTranslations.FieldByName('TranslatedText').AsWideString :=
              sValue;
            MemDtsTranslations.Post;
            Application.ProcessMessages;
          end;
      finally
        btnTranslate.Enabled := True;
      end;
    end;
  end;
end;

procedure TfrmMain.btnTranslateDictClick(Sender: TObject);
begin
  if MessageDlg('Confirmation',
    'This action perform a translation using a dictonary already loaded, are you sure?.',
    mtConfirmation, [mbYes, mbNo], 1) = mrYes then
  begin
    if (not MemDtsTranslations.IsEmpty) and (not MemDtsDictionary.IsEmpty) then
    begin
      try
        btnTranslateDict.Enabled := False;
        Screen.Cursor := crHourGlass;
        MemDtsTranslations.DisableControls;
        MemDtsTranslations.Filtered := False;
        MemDtsDictionary.DisableControls;
        pbTranslations.Max := MemDtsTranslations.RecordCount;
        pbTranslations.Position := 0;
        //MemDtsDictionary.SortOnFields('ApkName;FieldName', True, False);
        MemDtsTranslations.First;
        while not MemDtsTranslations.EOF do
        begin
          if MemDtsDictionary.Locate('APkName;FieldName',
            VarArrayOf([MemDtsTranslations.FieldByName('APkName').AsWideString,
            MemDtsTranslations.FieldByName('FieldName').AsWideString]), []) then
          begin
            if trim(MemDtsDictionary.FieldByName('TranslatedText').AsWideString) <>
              '' then
            begin
              MemDtsTranslations.Edit;
              MemDtsTranslations.FieldByName('TranslatedText').AsWideString :=
                MemDtsDictionary.FieldByName('TranslatedText').AsWideString;
              MemDtsTranslations.Post;
            end;

          end;
          pbTranslations.StepIt;
          MemDtsTranslations.Next;
          Application.ProcessMessages;
        end;
      finally
        MemDtsDictionary.Filtered := False;
        btnTranslateDict.Enabled := True;
        edtFilterChange(nil);
        MemDtsTranslations.EnableControls;
        MemDtsDictionary.EnableControls;
        Screen.Cursor := crDefault;
      end;
    end;
  end;
end;

procedure TfrmMain.btnWriteXML4AllClick(Sender: TObject);
var
  i: integer;
begin
  try
    if TButton(Sender).Name = 'btnWriteXML4All' then
      if MessageDlg('Confirmation',
        'Sure to write the translations to all languages in xml?',
        mtConfirmation, [mbYes, mbNo], 1) = mrNo then
        exit;
    btnWriteXML4All.Enabled := False;
    for i := 0 to cbTranslatedLang.Items.Count - 1 do
    begin
      cbTranslatedLang.ItemIndex := i;

      if (FileExistsUTF8(AppendPathDelim(ApplicationDirectory) +
        'Dictionary_' + cbOriginalLang.Text + '_' + cbTranslatedLang.Text + '.csv')) and
        (cbOriginalLang.Text <> cbTranslatedLang.Text) then
      begin
        // load dict
        btnLoadDictClick(self);
        Application.ProcessMessages;
        btnWriteXmlClick(self);
        Application.ProcessMessages;
      end;

    end;

  finally
    btnWriteXML4All.Enabled := True;
  end;

end;

procedure TfrmMain.btnWriteXmlClick(Sender: TObject);
var
  XMLDocument: TXMLDocument;
  Resources: TDOMNode; // Root Nod
  sName, sValue, sXmlFile, sAPKName, sXmlTranslatedFile, sResourcesDir: string;
  slDir, slLocLang: TStringList;
  sLangSource, sLangTranslated, sNameItem: string;
  sTranslatedText: WideString;
  i, j, h, k, l, iPosLang, iLines, iTranslated: integer;
begin
  if (not MemDtsDictionary.Active) or (MemDtsDictionary.IsEmpty) then
  begin
    MessageDlg('Warning', 'No Dictionary has been loaded or is empty.',
      mtWarning, [mbOK], 0);
    exit;
  end;

  if TButton(Sender).Name = 'btnWriteXml' then
    if MessageDlg('Confirmation', 'Sure to write the translations in xml?',
      mtConfirmation, [mbYes, mbNo], 1) = mrNo then
      exit;

  try
    btnWriteXml.Enabled := False;
    Screen.Cursor := crHourGlass;
    XMLDocument := TXMLDocument.Create;
    Resources := XMLDocument.DocumentElement;
    XMLDocument.Encoding := 'UTF-8';
    slDir := TStringList.Create;
    slLocLang := TStringList.Create;
    GetSubDirectories(ApplicationDirectory + csOutputDir,
      slDir);
    MemDtsDictionary.DisableControls;
    dsDictionary.DataSet:=nil;
    pbTranslations.Position := 0;
    pbTranslations.Max := slDir.Count;
    meLog.Lines.Add
    (DateTimeToStr(now) + ' - BEGIN TRANSLATION PROCESS for ' +
      cbOriginalLang.Text + ' to ' + cbTranslatedLang.Text);
    try
      for i := 0 to slDir.Count - 1 do
      begin
        sLangTranslated := cbTranslatedLang.Text;
        if chkStringFromValues.Checked then
          sLangSource := ''
        else
          sLangSource := '-' + cbOriginalLang.Text;
        try
          // main dir
          CreateDir(AppendPathDelim(AppendPathDelim(slDir[i]) + 'res') +
            'values-' + sLangTranslated);
          // regional dir only for framework
          if LowerCase(ExtractFileName(slDir[i])) = 'framework-res.apk' then
          begin
            MemDtsLanguages.First;
            while not MemDtsLanguages.EOF do
            begin
              if MemDtsLanguages.FieldByName('Language').AsString =
                sLangTranslated then
                CreateDir
                (AppendPathDelim(AppendPathDelim(slDir[i]) + 'res') +
                  'values-' + sLangTranslated + '-' +
                  MemDtsLanguages.FieldByName('Region').AsString);
              MemDtsLanguages.Next;
            end;
          end;

        except
          on e: Exception do
            meLog.Lines.Add('Error Creating directories in framework-res: ' + e.Message);

        end;

        for j := 0 to slFilesToTranslate.Count - 1 do
        begin
          if FileExistsUTF8(AppendPathDelim(AppendPathDelim(AppendPathDelim(slDir[i]) +
            'res') + 'values' + sLangSource) + slFilesToTranslate[j]) then
            sXmlFile := AppendPathDelim(AppendPathDelim(AppendPathDelim(slDir[i]) +
              'res') + 'values' + sLangSource) + slFilesToTranslate[j]
          else
          begin
            // at begin try in English-US
            if FileExistsUTF8(AppendPathDelim(AppendPathDelim(AppendPathDelim(slDir[i]) +
              'res') + 'values-' + LowerCase(cbOriginalLang.Text) + '-rUS') +
              slFilesToTranslate[j]) then
              sXmlFile := AppendPathDelim(AppendPathDelim(AppendPathDelim(slDir[i]) +
                'res') + 'values-' + LowerCase(cbOriginalLang.Text) + '-rUS') +
                slFilesToTranslate[j]
            else
              // search in all localizated languages
            begin
              GetSubDirectories(AppendPathDelim(AppendPathDelim(slDir[i]) + 'res'),
                slLocLang);
              iPosLang := FindMatchStr(slLocLang,
                AppendPathDelim(AppendPathDelim(slDir[i]) + 'res') +
                'values-' + LowerCase(cbOriginalLang.Text));
              if iPosLang >= 0 then
              begin
                sXmlFile := slLocLang[iPosLang] + slFilesToTranslate[j];
              end
              else
                sXmlFile := AppendPathDelim(AppendPathDelim(slDir[i] + 'res') +
                  'values') + slFilesToTranslate[j];
            end;

          end;
          sXmlTranslatedFile :=
            AppendPathDelim(AppendPathDelim(AppendPathDelim(slDir[i]) + 'res') +
            'values-' + sLangTranslated) + slFilesToTranslate[j];
          sAPKName := ExtractFileName(slDir[i]);
          if (FileExistsUTF8(sXmlFile)) and
            (DirectoryExists(AppendPathDelim(AppendPathDelim(slDir[i]) +
            'res') + 'values-' + sLangTranslated)) then
          begin
            try
              iLines := 0;
              iTranslated := 0;
              if FileExistsUTF8(sXmlFile) then
              begin
                sName := '';
                ReadXMLFile(XMLDocument, sXmlFile);
                XMLDocument.Encoding := 'UTF-8';
                Resources := XMLDocument.DocumentElement;
                // strings.xml
                if slFilesToTranslate[j] = 'strings.xml' then
                begin
                  sName := '';
                  for h := 0 to Resources.ChildNodes.Count - 1 do
                    if Resources.ChildNodes[h].HasAttributes then
                    begin
                      try
                        l := Resources.ChildNodes[h].ChildNodes.Count - 1;
                        sName :=
                          UTF8Encode(
                          Resources.ChildNodes[h].Attributes.Item[0].NodeValue);
                        if l = 0 then
                          sValue :=
                            UTF8Encode(Resources.ChildNodes[h].TextContent)
                        else
                        begin
                          if Resources.ChildNodes[h].HasChildNodes then
                            sValue :=
                              UTF8Encode(Resources.ChildNodes[h].ChildNodes[l].NodeValue)
                          else
                            sValue := UTF8Encode(Resources.ChildNodes[h].NodeValue);
                        end;

                        if (trim(sName) <> '') and (HaveLetters(sValue)) and
                          (trim(sValue) <> '') then
                        begin
                          Inc(iLines);
                          sTranslatedText := '';
                          if MemDtsDictionary.Locate('APkName;FieldName',
                            VarArrayOf([sAPKName, sName]), []) then
                          begin

                            if trim(
                              MemDtsDictionary.FieldByName(
                              'TranslatedText').AsWideString) <> '' then
                            begin
                              Inc(iTranslated);
                              sTranslatedText :=
                                MemDtsDictionary.FieldByName(
                                'TranslatedText').AsWideString;
                              if sTranslatedText = '*****' then
                                sTranslatedText := '';

                              if not
                                Resources.ChildNodes[h].ChildNodes[0].HasChildNodes then
                              begin

                                TDOMElement(
                                  Resources.ChildNodes[h].ChildNodes[0]).NodeValue :=
                                  UTF8Decode(sTranslatedText);

                              end;
                            end;
                          end;

                        end;
                      except

                      end;
                    end;
                end;
                // Plurals
                if slFilesToTranslate[j] = 'plurals.xml' then
                begin
                  // plurals
                  for h := 0 to Resources.ChildNodes.Count - 1 do
                    if Resources.ChildNodes[h].HasAttributes then
                    begin
                      // item
                      try
                        for k :=
                          0 to Resources.ChildNodes[h].ChildNodes.Count - 1 do
                        begin
                          sNameItem := '';
                          if Resources.ChildNodes[h].ChildNodes[k].HasAttributes
                          then
                          begin
                            sName :=
                              UTF8Encode(
                              Resources.ChildNodes[h].Attributes.Item[0].NodeValue);
                            sNameItem :=
                              UTF8Encode(
                              Resources.ChildNodes[h].ChildNodes[
                              k].Attributes.Item[0].NodeValue);
                            sValue :=
                              UTF8Encode(
                              Resources.ChildNodes[h].ChildNodes[
                              k].TextContent);
                          end;
                          if (trim(sNameItem) <> '') then
                          begin
                            Inc(iLines);
                            sTranslatedText := '';
                            if MemDtsDictionary.Locate(
                              'APkName;FieldName', VarArrayOf(
                              [sAPKName, sName + '-' + sNameItem]), []) then
                            begin

                              sTranslatedText :=
                                MemDtsDictionary.FieldByName(
                                'TranslatedText').AsWideString;
                              if sTranslatedText <> '' then
                              begin
                                if sTranslatedText = '*****' then
                                  sTranslatedText := '';

                                Inc(iTranslated);
                                TDOMElement(
                                  Resources.ChildNodes[h].ChildNodes[
                                  k].ChildNodes[0]).NodeValue :=
                                  UTF8Decode(sTranslatedText);

                              end;
                            end;

                          end;
                        end;
                      except

                      end;
                    end;
                end;
                // arrays
                if slFilesToTranslate[j] = 'arrays.xml' then
                begin
                  for h := 0 to Resources.ChildNodes.Count - 1 do
                    if (Resources.ChildNodes[h].NodeName = 'string-array') and
                      (Resources.ChildNodes[h].HasAttributes) then
                    begin
                      try
                        for k :=
                          0 to Resources.ChildNodes[h].ChildNodes.Count - 1 do
                        begin
                          sName :=
                            UTF8Encode(
                            Resources.ChildNodes[h].Attributes.Item[0].NodeValue);
                          sNameItem :=
                            sName + '-' + sName + '-string-array-item' + IntToStr(k);
                          sValue :=
                            UTF8Encode(
                            Resources.ChildNodes[h].ChildNodes[
                            k].TextContent);
                          // search apkname + fieldname
                          if (trim(sNameItem) <> '') and
                            (pos('_values', sName) <= 0) then
                          begin
                            Inc(iLines);
                            if MemDtsDictionary.Locate(
                              'APkName;FieldName', VarArrayOf(
                              [sAPKName, sNameItem]), []) then
                            begin
                              Inc(iTranslated);
                              sTranslatedText :=
                                MemDtsDictionary.FieldByName(
                                'TranslatedText').AsWideString;
                              if sTranslatedText = '*****' then
                                sTranslatedText := '';
                              TDOMElement(
                                Resources.ChildNodes[h].ChildNodes[
                                k].ChildNodes[0]).NodeValue :=
                                UTF8Decode(sTranslatedText);
                            end;
                          end;
                        end;
                      except

                      end;

                    end;
                end;
              end;
            finally
              meLog.Lines.Add('    ->' + sXmlTranslatedFile + ' ' +
                IntToStr(iLines) + ' lines to translate and ' +
                IntToStr(iTranslated) + ' are translated.');
              WriteXMLFile(XMLDocument, sXmlTranslatedFile);
              // copy xml to regional dir if framework-res
              try
                if LowerCase(ExtractFileName(slDir[i])) =
                  'framework-res.apk' then
                begin
                  MemDtsLanguages.First;
                  while not MemDtsLanguages.EOF do
                  begin
                    if MemDtsLanguages.FieldByName('Language').AsString =
                      sLangTranslated then
                      CopyFile(sXmlTranslatedFile,
                        AppendPathDelim(AppendPathDelim(AppendPathDelim(slDir[i]) +
                        'res') + 'values-' + sLangTranslated + '-' +
                        MemDtsLanguages.FieldByName('Region').AsString) +
                        slFilesToTranslate[j], False);
                    MemDtsLanguages.Next;
                  end;

                end;
              except

              end;
              // copy the images... Resources from translated pictures or original lang

              sResourcesDir :=
                AppendPathDelim(ApplicationDirectory + csResourcesDir) +
                chkListForPacking.Items[i];
              if DirectoryExists(sResourcesDir) then
              begin
                CopyFolder(sResourcesDir, AppendPathDelim(slDir[i]));
              end;

              // if framework-res.apk we must delete the directory without region
              if LowerCase(ExtractFileName(slDir[i])) =
                'framework-res.apk' then
              begin
                DeleteFile(sXmlTranslatedFile);
              end;
            end;
          end;

        end;

        // if framework-res.apk we must delete the directory without region
        if LowerCase(ExtractFileName(slDir[i])) = 'framework-res.apk' then
        begin
          RemoveDir(ExtractFilePath(sXmlTranslatedFile));
        end;
        pbTranslations.StepIt;
        Application.ProcessMessages;
      end;
    except
    end
  finally
    XMLDocument.Free;
    Resources.Free;
    slDir.Free;
    slLocLang.Free;
    meLog.Lines.Add(DateTimeToStr(now) + ' - END TRANSLATION PROCESS for ' +
      cbOriginalLang.Text + ' to ' + cbTranslatedLang.Text);
    // Run Script AfterWriteXml
    meLog.Lines.Add
    (DateTimeToStr(now) + ' - Running Script AfterWriteXML: ');
    RunAppInMemo('"' + AppendPathDelim(ApplicationDirectory + csScriptsDir) +
      'AfterWriteXML' + cbOriginalLang.Text + cbTranslatedLang.Text +
      csScriptExt + '"', meLog);
    dsDictionary.DataSet:=MemDtsDictionary;
    MemDtsDictionary.EnableControls;
    btnWriteXml.Enabled := True;
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMain.cbTranslatedLangChange(Sender: TObject);
begin
  if TComboBox(Sender).Name = 'cbTranslatedLang' then
  begin
    MemDtsDictionary.Active := False;
  end;
end;


procedure TfrmMain.dbgDataMouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
var
  pt: TGridCoord;
begin
  pt := dbgData.MouseCoord(X, Y);
  if pt.Y = 0 then
    dbgData.Cursor := crHandPoint
  else
    dbgData.Cursor := crDefault;
end;

procedure TfrmMain.dbgDataPrepareCanvas(Sender: TObject; DataCol: integer;
  Column: TColumn; AState: TGridDrawState);
begin
  if (not MemDtsTranslations.ControlsDisabled) and (MemDtsTranslations.Active) and
    (not MemDtsTranslations.IsEmpty) then
  begin
    if trim(MemDtsTranslations.FieldByName('TranslatedText').AsString) = '' then
      dbgData.Canvas.Brush.Color := clYellow
    else
      dbgData.Canvas.Brush.Color := clMoneyGreen;
    if trim(MemDtsTranslations.FieldByName('TranslatedText').AsString) = '*****' then
      dbgData.Canvas.Brush.Color := clRed;
    if MemDtsTranslations.RecNo = giActualRecord then
    begin
      dbgData.Canvas.Font.Style := dbgData.Canvas.Font.Style + [fsBold];
      dbgData.Canvas.Font.Color := clBlack;
    end;
  end;
end;


procedure TfrmMain.dbgDataTitleClick(Column: TColumn);
{$J+}
const
  PreviousColumnIndex: integer = 0;
{$J-}
begin
  dbgData.Columns[PreviousColumnIndex].title.Font.Style :=
    dbgData.Columns[PreviousColumnIndex].title.Font.Style - [fsBold];
  Column.title.Font.Style := Column.title.Font.Style + [fsBold];
  PreviousColumnIndex := Column.Index;
  SortBufDataSet(MemDtsTranslations, Column.FieldName);
  gsFilterField := Column.FieldName;
  edtFilter.Text := '';
  lblFilterField.Caption := 'Filter by ' + Column.FieldName + ':';
end;

procedure TfrmMain.dsTranslationsDataChange(Sender: TObject; Field: TField);
begin
  if not MemDtsTranslations.ControlsDisabled then
  begin
    giActualRecord := MemDtsTranslations.RecNo;
    dbgData.Repaint;
  end;
end;

procedure TfrmMain.edtFilterChange(Sender: TObject);
begin
  if (length(edtFilter.Text) > 0) and (not MemDtsTranslations.IsEmpty) then
  begin
    try
      MemDtsTranslations.Filter :=
        gsFilterField + ' = ' + QuotedStr(edtFilter.Text + '*');
      MemDtsTranslations.Filtered := True;
    except
      Beep;
    end;
  end
  else
    MemDtsTranslations.Filtered := False;
end;

procedure TfrmMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  MemDtsDictionary.Close;
  MemDtsDictionary.Free;
  MemDtsTranslations.Close;
  MemDtsTranslations.Free;
end;


procedure TfrmMain.pnlDecodeBottomClick(Sender: TObject);
begin

end;

procedure TfrmMain.pnlTranslationsMiddleClick(Sender: TObject);
begin

end;

function TfrmMain.SaveDictionary(sFile: string): boolean;
var
  Writer: TextFile;
  sLine: UTF8String;
begin
  try
    Result := False;
    AssignFile(Writer, sFile);
       {$I-}
    Rewrite(Writer);
    MemDtsDictionary.Active := True;
    sLine := '"ApkName","FieldName","OriginalText","TranslatedText",';
    WriteLn(Writer, sLine);
    MemDtsDictionary.DisableControls;
    while not MemDtsDictionary.EOF do
    begin
      sLine := '"' + MemDtsDictionary.FieldByName('ApkName')
        .AsString + '","' + MemDtsDictionary.FieldByName('FieldName')
        .AsString + '","' + MemDtsDictionary.FieldByName('OriginalText')
        .AsString + '","' + MemDtsDictionary.FieldByName('TranslatedText')
        .AsString + '",';
      Writeln(Writer, sLine);
      MemDtsDictionary.Next;
    end;
  finally
        {$I+}
    CloseFile(Writer);
    Result := True;
    MemDtsDictionary.First;
    MemDtsDictionary.EnableControls;
  end;
end;


procedure TfrmMain.btnSaveDictClick(Sender: TObject);
var
  sFile: string;
begin
  if not MemDtsDictionary.IsEmpty then
  begin
    sFile := AppendPathDelim(ApplicationDirectory) + 'Dictionary_'  +
      cbOriginalLang.Text + '_' + cbTranslatedLang.Text + '.csv';
    if FileExistsUTF8(sFile) then
    begin
      if MessageDlg('Confirmation',
        'The dictionary exists, do you want overwrite it?', mtConfirmation,
        [mbYes, mbNo], 1) = mrYes then
      begin
        if SaveDictionary(sFile) then
          MessageDlg('Information', 'The Dictonary has been saved',
            mtInformation, [mbOK], 0);
      end;

    end
    else
    begin
      if SaveDictionary(sFile) then
        MessageDlg('Information', 'The Dictonary has been saved',
          mtInformation, [mbOK], 0);
    end;
  end;
end;



end.
