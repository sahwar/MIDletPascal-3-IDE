(*
    MIDletPascal 3.0 IDE
    by Javier Santo Domingo (j-a-s-d@users.sourceforge.net)
*)

unit mp3MainFrame;

interface

uses
  Windows, SysUtils, Classes, Forms, Controls, Menus,
  gnugettext,
  sitFileUtils, sitEditorsFrame, sitEditorFrame, sitFrame,
  sitMPHexEditorFrame, sitPNGImageEditorFrame,
  mp3CodeEditorFrame, mp3WelcomePageFrame,
  mp3FileKind, mp3Consts, mp3Settings;

type
  Tmp3MainFrame = class(TsitEditorsFrame)
  private
    FWelcomePage: Tmp3WelcomePageFrame;
    FOnCodeEditorPreprocess: TNotifyEvent;
    FOnCodeEditorHistory: TNotifyEvent;
    FOnCodeEditorBrowseClassFile: TNotifyEvent;
    FOnCodeEditorOpenFileAtCursor: TNotifyEvent;
    FOnCodeEditorGetHelpOnWord: TNotifyEvent;
    FOnCodeEditorRollback: TNotifyEvent;
    FOnCodeEditorSendToBuffer: TNotifyEvent;
    FOnCodeEditorCaretMove: TNotifyEvent;
    procedure OnCodeCaretMove(Sender: TObject);
    procedure OnCodeGetHelpOnWord(Sender: TObject);
    procedure OnCodeOpenFileAtCursor(Sender: TObject);
    procedure OnCodeRollback(Sender: TObject);
    procedure OnCodeSendToBuffer(Sender: TObject);
    procedure OnCodeHistory(Sender: TObject);
    procedure OnCodePreprocess(Sender: TObject);
    procedure OnCodeBrowseClassFile(Sender: TObject);
    function NewEditor(AKind: TsitEditorKind): TsitEditorFrame;
    procedure InitWelcomePage;
  public
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    procedure RefreshCodeEditorStyle;
    procedure RefreshTranslation;
    procedure NewCodeEditor(AFilename: string = ''; AShowPreprocessTab: boolean = true;
      AShowHistoryTab: boolean = true; ANew: boolean = false);
    procedure NewHexEditor(AFilename: string = ''; ANew: boolean = false);
    procedure NewImageEditor(AFilename: string = '';
      AWidth: integer = 12; AHeight: integer = 12; ANew: boolean = false);
    procedure GotoSourceFileLine(const AFilename: string; ALine: Integer);
    property OnCodeEditorCaretMove: TNotifyEvent
      read FOnCodeEditorCaretMove write FOnCodeEditorCaretMove;
    property OnCodeEditorPreprocess: TNotifyEvent
      read FOnCodeEditorPreprocess write FOnCodeEditorPreprocess;
    property OnCodeEditorHistory: TNotifyEvent
      read FOnCodeEditorHistory write FOnCodeEditorHistory;
    property OnCodeEditorBrowseClassFile: TNotifyEvent
      read FOnCodeEditorBrowseClassFile write FOnCodeEditorBrowseClassFile; 
    property OnCodeEditorOpenFileAtCursor: TNotifyEvent
      read FOnCodeEditorOpenFileAtCursor write FOnCodeEditorOpenFileAtCursor;
    property OnCodeEditorGetHelpOnWord: TNotifyEvent
      read FOnCodeEditorGetHelpOnWord write FOnCodeEditorGetHelpOnWord;
    property OnCodeEditorRollback: TNotifyEvent
      read FOnCodeEditorRollback write FOnCodeEditorRollback;
    property OnCodeEditorSendToBuffer: TNotifyEvent
      read FOnCodeEditorSendToBuffer write FOnCodeEditorSendToBuffer;
    property WelcomePage: Tmp3WelcomePageFrame read FWelcomePage;
  end;

implementation

{$R *.dfm}

uses
  sitSynCodeEditorStylesPas;

var
  lMainFrame: Tmp3MainFrame;

{ Tmp3MainFrame }

procedure Tmp3MainFrame.AfterConstruction;
begin
  inherited;
  lMainFrame := Self;
  InitWelcomePage;
  gSynCodeEditorStylesPasDialogApplyHandler := RefreshCodeEditorStyle;
end;

procedure Tmp3MainFrame.BeforeDestruction;
begin
  inherited;
  //
end;

procedure Tmp3MainFrame.GotoSourceFileLine(const AFilename: string;
  ALine: Integer);
begin
  NewCodeEditor(AFilename);
  with CurrentEditor do begin
    SetFocusOnEditor;
    GotoOffset(ALine);
  end;
end;

function Tmp3MainFrame.NewEditor(AKind: TsitEditorKind): TsitEditorFrame;
var s: string;
begin
  result := nil;
  s := GetCurrentLanguage;
  UseLanguage('en');
  case AKind of
  ekCode:  result := Tmp3CodeEditorFrame.Create(Self);
  ekHex: result := TsitMPHexEditorFrame.Create(Self);
  ekImage: result := TsitPNGImageEditorFrame.Create(Self);
  end;
  TranslateComponent(result);
  UseLanguage(s);
  RetranslateComponent(result);
end;

procedure Tmp3MainFrame.NewCodeEditor(AFilename: string = ''; AShowPreprocessTab: boolean = true;
  AShowHistoryTab: boolean = true; ANew: boolean = false);
var codeEditor: Tmp3CodeEditorFrame;
begin
  if CheckAlreadyBeingEdited(AFilename,ekCode) then
    exit;
  codeEditor := Tmp3CodeEditorFrame(NewEditor(ekCode));
  codeEditor.OnCaretMove := OnCodeCaretMove;
  codeEditor.OnPreprocess := OnCodePreprocess;
  codeEditor.OnOpenFileAtCursor := OnCodeOpenFileAtCursor;
  codeEditor.OnGetHelpOnWord := OnCodeGetHelpOnWord;
  codeEditor.OnHistory := OnCodeHistory;
  codeEditor.OnBrowseClassFile := OnCodeBrowseClassFile;
  codeEditor.OnRollback := OnCodeRollback;
  codeEditor.OnSendToBuffer := OnCodeSendToBuffer;
  codeEditor.SetPreprocessTabVisibility(AShowPreprocessTab);
  codeEditor.SetHistoryTabVisibility(AShowHistoryTab);
  AddEditor(codeEditor);
  codeEditor.ImageIndex := 8;
  codeEditor.SetColorSpeedSetting(gSettings.CodeEditorStyle);
  codeEditor.IsNew := ANew;
  if (AFilename <> '') and not ANew then
    codeEditor.Load(AFilename)
  else
    codeEditor.Content := Format(NEW_UNIT_PATTERN,['']);
  try
    codeEditor.SetFocusOnEditor;
  except
  end;
end;

procedure Tmp3MainFrame.NewHexEditor(AFilename: string = ''; ANew: boolean = false);
begin
  if CheckAlreadyBeingEdited(AFilename,ekHex) then
    exit;
  AddEditor(NewEditor(ekHex));
  CurrentEditor.ImageIndex := 15;
  CurrentEditor.IsNew := ANew;
  if (AFilename <> '') and not ANew then
    CurrentEditor.Load(AFilename);
  try
    CurrentEditor.SetFocusOnEditor;
  except
  end;
end;

procedure Tmp3MainFrame.NewImageEditor(AFilename: string = '';
  AWidth: integer = 12; AHeight: integer = 12; ANew: boolean = false);
begin
  if CheckAlreadyBeingEdited(AFilename,ekImage) then
    exit;
  AddEditor(NewEditor(ekImage));
  CurrentEditor.ImageIndex := 18;
  TsitPNGImageEditorFrame(CurrentEditor).SetWidth(AWidth);
  TsitPNGImageEditorFrame(CurrentEditor).SetHeight(AHeight);
  CurrentEditor.IsNew := ANew;
  if (AFilename <> '') and not ANew then
    CurrentEditor.Load(AFilename)
  else begin
    CurrentEditor.Filename := AFilename;
    CurrentEditor.Load('');
  end;
  try
    CurrentEditor.SetFocusOnEditor;
  except
  end;
end;

procedure Tmp3MainFrame.OnCodeCaretMove(Sender: TObject);
begin
  if assigned(FOnCodeEditorCaretMove) then
    FOnCodeEditorCaretMove(Sender);
end;

procedure Tmp3MainFrame.OnCodeGetHelpOnWord(Sender: TObject);
begin
  if assigned(FOnCodeEditorGetHelpOnWord) then
    FOnCodeEditorGetHelpOnWord(Sender);
end;

procedure Tmp3MainFrame.OnCodeBrowseClassFile(Sender: TObject);
begin
  if assigned(FOnCodeEditorBrowseClassFile) then
    FOnCodeEditorBrowseClassFile(Sender);
end;

procedure Tmp3MainFrame.OnCodeHistory(Sender: TObject);
begin
  if assigned(FOnCodeEditorHistory) then
    FOnCodeEditorHistory(Sender);
end;

procedure Tmp3MainFrame.OnCodePreprocess(Sender: TObject);
begin
  if assigned(FOnCodeEditorPreprocess) then
    FOnCodeEditorPreprocess(Sender);
end;

procedure Tmp3MainFrame.OnCodeOpenFileAtCursor(Sender: TObject);
begin
  if assigned(FOnCodeEditorOpenFileAtCursor) then
    FOnCodeEditorOpenFileAtCursor(Sender);
end;

procedure Tmp3MainFrame.OnCodeRollback(Sender: TObject);
begin
  if assigned(FOnCodeEditorRollback) then
    FOnCodeEditorRollback(Sender);
end;

procedure Tmp3MainFrame.OnCodeSendToBuffer(Sender: TObject);
begin
  if assigned(FOnCodeEditorSendToBuffer) then
    FOnCodeEditorSendToBuffer(Sender);
end;

procedure Tmp3MainFrame.RefreshCodeEditorStyle;
var i: integer;
begin
  for i := 0 to FFrames.Count - 1 do
    if TsitFrame(FFrames[i]) is TsitEditorFrame then
      if TsitEditorFrame(FFrames[i]).Kind = ekCode then
        Tmp3CodeEditorFrame(FFrames[i]).SetColorSpeedSetting(gSettings.CodeEditorStyle);
end;

procedure Tmp3MainFrame.RefreshTranslation;
var i: integer;
begin
  for i := 0 to FFrames.Count - 1 do
    RetranslateComponent(FFrames[i]);
end;

procedure Tmp3MainFrame.InitWelcomePage;
var s: string;
begin
  if not assigned(FWelcomePage) then begin
    s := GetCurrentLanguage;
    UseLanguage('en');
    FWelcomePage := Tmp3WelcomePageFrame.Create(Self);
    AddFrame(FWelcomePage);
    FWelcomePage.SetTitle(_('Welcome'));
    TranslateComponent(FWelcomePage);
    UseLanguage(s);
    RetranslateComponent(FWelcomePage);
  end;
  FWelcomePage.Tab.Click;
end;

// GetCodeContent

function GetCodeContent(AFileName: string; var AContent: string): boolean;
var editor: TsitEditorFrame; i: integer;
begin
  result := false;
  AContent := '';
  if assigned(lMainFrame) then
    for i := 0 to lMainFrame.FFrames.Count-1 do
      if TsitFrame(lMainFrame.FFrames[i]) is TsitEditorFrame then
      begin
        editor := TsitEditorFrame(lMainFrame.FFrames[i]);
        if (editor.Kind=ekCode)and SameText(editor.Filename,AFilename) then
        begin
          AContent := Tmp3CodeEditorFrame(editor).Content;
          result := true;
          break;
        end;
      end;
end;

initialization
  sitFileUtils.ExternalGetFileContent := GetCodeContent;
end.
