unit ac3rdPartyEditor;
{$I sDefs.inc}

interface

uses
  Windows, Messages, SysUtils, {$IFDEF DELPHI6}Variants, {$ENDIF}Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, sBitBtn, ComCtrls, sListView, sSkinManager,
  sSkinProvider, sSpeedButton, Menus, ExtCtrls, sPanel,
  sCheckListBox, sCheckBox, sLabel, sListBox;

type
  TForm3rdPartyEditor = class(TForm)
    sListView1: TsListView;
    sBitBtn1: TsBitBtn;
    sBitBtn2: TsSpeedButton;
    sBitBtn3: TsSpeedButton;
    sBitBtn4: TsSpeedButton;
    sSkinProvider1: TsSkinProvider;
    PopupMenu1: TPopupMenu;
    Addnew1: TMenuItem;
    Delete1: TMenuItem;
    Defaultsettings1: TMenuItem;
    N1: TMenuItem;
    Exit1: TMenuItem;
    sSpeedButton1: TsSpeedButton;
    sSpeedButton2: TsSpeedButton;
    sSpeedButton3: TsSpeedButton;
    sSpeedButton4: TsSpeedButton;
    sSpeedButton5: TsSpeedButton;
    SaveDialog1: TSaveDialog;
    OpenDialog1: TOpenDialog;
    sSpeedButton6: TsSpeedButton;
    sPanel1: TsPanel;
    sListBox1: TsListBox;
    sPanel2: TsPanel;
    sListBox2: TsCheckListBox;
    Edit1: TMenuItem;
    sCheckBox1: TsCheckBox;
    sCheckBox2: TsCheckBox;
    sLabel1: TsLabel;
    procedure sBitBtn2Click(Sender: TObject);
    procedure sBitBtn1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure sBitBtn3Click(Sender: TObject);
    procedure sBitBtn4Click(Sender: TObject);
    procedure sSpeedButton1Click(Sender: TObject);
    procedure sListView1Change(Sender: TObject; Item: TListItem; Change: TItemChange);
    procedure sListBox1Click(Sender: TObject);
    procedure sSpeedButton2Click(Sender: TObject);
    procedure sListView1ColumnClick(Sender: TObject; Column: TListColumn);
    procedure sSpeedButton3Click(Sender: TObject);
    procedure sSpeedButton4Click(Sender: TObject);
    procedure sSpeedButton5Click(Sender: TObject);
    procedure sSpeedButton6Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Edit1Click(Sender: TObject);
    procedure sCheckBox1Click(Sender: TObject);
    procedure sListView1DblClick(Sender: TObject);
  public
    SM : TsSkinManager;
    procedure Populate(ControlRepaint : boolean = True);
    procedure SelectCtrls(TypeIndex : integer);
  end;

var
  Form3rdPartyEditor: TForm3rdPartyEditor;

const
{$IFDEF ALITE}
  acLiteCtrls : array [0..17] of string = ('TBitBtn', 'TButton', 'TCategoryButtons', 'TCheckBox', 'TCheckListBox', 'TColorBox', 'TComboBox',
                'TComboBoxEx', 'TDrawGrid', 'TEdit', 'TFileListBox', 'TGridPanel', 'TGroupBox', 'TGroupButton',
                'THotKey', 'TListView', 'TMemo', 'TPage');
{$ENDIF}
  // Arrary of predefined ctrls
  acCtrlsArray : array [0..13] of string = (
  // 0. Std. VCL
    'TEdit=Edit'#13#10 +
    'TMemo=Edit'#13#10 +
    'TMaskEdit=Edit'#13#10 +
    'TSpinEdit=Edit'#13#10 +
    'TLabeledEdit=Edit'#13#10 +
    'THotKey=Edit'#13#10 +
    'TListBox=Edit'#13#10 +
    'TCheckListBox=Edit'#13#10 +
    'TRichEdit=Edit'#13#10 +
    'TSpinEdit=Edit'#13#10 +
    'TDateTimePicker=Edit'#13#10 +
    'TStringGrid=Grid'#13#10 +
    'TDrawGrid=Grid'#13#10 +
    'TValueListEditor=Grid'#13#10 +
    'TTreeView=TreeView'#13#10 +
    'TCategoryButtons=Edit'#13#10 +
    'TSpinButton=UpDownBtn'#13#10 + 
    'TListView=ListView'#13#10 +
    'TScrollBar=ScrollBar'#13#10 +
{.$IFNDEF ALITE}
    'TPanel=Panel'#13#10 +
    'TPage=Panel'#13#10 +
    'TGridPanel=Panel'#13#10 +
    'TButton=Button'#13#10 +
    'TFileListBox=Edit'#13#10 +
    'TBitBtn=BitBtn'#13#10 +
    'TCheckBox=CheckBox'#13#10 +
    'TRadioButton=CheckBox'#13#10 +
    'TGroupButton=CheckBox'#13#10 +
    'TGroupBox=GroupBox'#13#10 +
    'TRadioGroup=GroupBox'#13#10 +
    'TComboBox=ComboBox'#13#10 +
    'TComboBoxEx=ComboBox'#13#10 +
    'TColorBox=ComboBox'#13#10 +
    'TPageControl=PageControl'#13#10 +
    'TTabControl=TabControl'#13#10 +
    'TToolBar=ToolBar'#13#10 +
{$IFDEF ADDWEBBROWSER}    
    'TWebBrowser=WebBrowser'#13#10 +
{$ENDIF}    
{.$ENDIF}
    'TStatusBar=StatusBar'#13#10 +
    'TScrollBox=ScrollControl'#13#10 +
    'TUpDown=UpDownBtn'#13#10 +
    'TSpeedButton=SpeedButton',

  // 1. Std. DB-aware
    'TDBListBox=Edit'#13#10 +
    'TDBMemo=Edit'#13#10 +
    'TDBNavigator=Panel'#13#10 +
    'TDBLookupListBox=Edit'#13#10 +
    'TDBRichEdit=Edit'#13#10 +
    'TDBCtrlGrid=Edit'#13#10 +
    'TDBEdit=Edit'#13#10 +
    'TDBRadioGroup=GroupBox'#13#10 +
    'TDBCtrlPanel=Panel'#13#10 +
    'TDBCheckBox=CheckBox'#13#10 +
    'TDBGrid=Grid'#13#10 +
    'TNavButton=SpeedButton'#13#10 +
    'TDBTreeView=TreeView'#13#10 +
    'TDBComboBox=ComboBox'#13#10 +
    'TDBLookupComboBox=WWEdit',

  // 2. TNT Controls
    'TTntEdit=Edit'#13#10 +
    'TTntMemo=Edit'#13#10 +
    'TTntListBox=Edit'#13#10 +
    'TTntCheckListBox=Edit'#13#10 +
    'TTntRichEdit=Edit'#13#10 +
    'TTntDBEdit=Edit'#13#10 +
    'TTntDBMemo=Edit'#13#10 +
    'TTntDBRichEdit=Edit'#13#10 +
    'TTntPanel=Panel'#13#10 +
    'TTntButton=Button'#13#10 +
    'TTntButton=Button'#13#10 +
    'TTntBitBtn=BitBtn'#13#10 +
    'TTntCheckBox=CheckBox'#13#10 +
    'TTntRadioButton=CheckBox'#13#10 +
    'TTntDBCheckBox=CheckBox'#13#10 +
    'TTntDBRadioButton=CheckBox'#13#10 +
    'TTntGroupButton=CheckBox'#13#10 +
    'TTntGroupBox=GroupBox'#13#10 +
    'TTntRadioGroup=GroupBox'#13#10 +
    'TTntDBRadioGroup=GroupBox'#13#10 +
    'TTntStringGrid=Grid'#13#10 +
    'TTntDrawGrid=Grid'#13#10 +
    'TTntDBGrid=Grid'#13#10 +
    'TTntTreeView=TreeView'#13#10 +
    'TTntComboBox=ComboBox'#13#10 +
    'TTntDBComboBox=ComboBox'#13#10 +
    'TTntListView=ListView'#13#10 +
    'TTntSpeedButton=SpeedButton',

  // 3. Woll2Woll
    'TwwDBGrid=Grid'#13#10 +
    'TwwRadioGroup=GroupBox'#13#10 +
    'TwwDBComboBox=wwEdit'#13#10 +
    'TwwDBEdit=wwEdit'#13#10 +
    'TwwDBCustomCombo=wwEdit'#13#10 +
    'TwwTempKeyCombo=ComboBox'#13#10 +
    'TwwIncrementalSearch=Edit'#13#10 +
    'TwwDBCustomLookupCombo=wwEdit'#13#10,
  // 4. Virtual controls
    'TVirtualStringTree=VirtualTree'#13#10 +
    'TVirtualStringTreeDB=VirtualTree'#13#10 +
    'TEasyListview=VirtualTree'#13#10 +
    'TVirtualExplorerListview=VirtualTree'#13#10 +
    'TVirtualExplorerTreeview=VirtualTree'#13#10 +
    'TVirtualExplorerTree=VirtualTree'#13#10 +
    'TVirtualExplorerEasyListview=VirtualTree'#13#10 +
    'TVirtualDrawTree=VirtualTree',
  // 5. EhLib
    'TDBGridEh=GridEh'#13#10,
  // 6. FastReport & QuickReport
    'TfrxPreviewWorkspace=Edit'#13#10 +
    'TfrxScrollBox=Edit'#13#10 +
    'TQRPreview=Edit'#13#10 +
    'TStatusBar=StatusBar'#13#10 +
    'TSpeedButton=SpeedButton'#13#10 +
    'TPanel=Panel'#13#10 +
    'TButton=Button'#13#10 +
    'TToolBar=ToolBar'#13#10 +
    'TfrxTBPanel=Panel',
  // 7. RxLib
    'TRxDBGrid=Grid',
  // 8. Jvcl
    'TJvCharMap=Edit'#13#10 +
    'TJvImagesViewer=Edit'#13#10 +
    'TJvImageListViewer=Edit'#13#10 +
    'TJvOwnerDrawViewer=Edit'#13#10 +
    'TJvDBRichEdit=Edit'#13#10 +
    'TJvDBLookupList=Edit'#13#10 +
    'TJvDBMaskEdit=Edit'#13#10 +
    'TJvDBSearchEdit=Edit'#13#10 +
    'TJvDBFindEdit=Edit'#13#10 +
    'TJvValidateEdit=Edit'#13#10 +
    'TJvEditor=Edit'#13#10 +
    'TJvHLEditor=Edit'#13#10 +
    'TJvWideEditor=Edit'#13#10 +
    'TJvWideHLEditor=Edit'#13#10 +
    'TJvEdit=Edit'#13#10 +
    'TJvMemo=Edit'#13#10 +
    'TJvRichEdit=Edit'#13#10 +
    'TJvMaskEdit=Edit'#13#10 +
    'TJvCheckedMaskEdit=Edit'#13#10 +
    'TJvHotKey=Edit'#13#10 +
    'TJvIPAddress=Edit'#13#10 +
    'TJvgListBoxt'#13#10 +
    'TJvgCheckListBox=Edit'#13#10 +
    'TJvgAskListBox=Edit'#13#10 +
    'TJvCSVEdit=Edit'#13#10 +
    'TJvListBox=Edit'#13#10 +
    'TJvCheckListBox=Edit'#13#10 +
    'TJvTextListBox=Edit'#13#10 +
    'TJvxCheckListBox=Edit'#13#10 +
    'TJvImageListBoxdit'#13#10 +
    'TJvComboListBox=Edit'#13#10 +
    'TJvHTListBox=Edit'#13#10 +
    'TJvUninstallListBox=Edit'#13#10 +
    'TJvFileListBox=Edit'#13#10 +
    'TJvDirectoryListBox=Edit'#13#10 +

    'TJvControlPanelButton=Button'#13#10 +
    'TJvStartMenuButton=Button'#13#10 +
    'TJvRecentMenuButton'#13#10 +
    'TJvFavoritesButton=Button'#13#10 +
    'TJvHTButton=Button'#13#10 +

    'TJvBitBtn=BitBtn'#13#10 +
    'TJvImgBtn=BitBtn'#13#10 +

    'TJvDBCheckBox=CheckBox'#13#10 +
    'TJvCheckBox=CheckBox'#13#10 +
    'TJvRadioButton=CheckBox'#13#10 +
    'TGroupButton=CheckBox'#13#10 +
    'TJvCheckBox=CheckBox'#13#10 +

    'TJvRadioGroup=GroupBox'#13#10 +
    'TJvGroupBox=GroupBox'#13#10 +

    'TJvGroupBox=ListView'#13#10 +
    'TJvPanel=Panel'#13#10 +

    'TJvDBGrid=Grid'#13#10 +
    'TJvDBUltimGrid=Grid'#13#10 +
    'TJvgStringGrid=Grid'#13#10 +
    'TJvDrawGrid=Grid'#13#10 +
    'TJvStringGrid=Grid'#13#10 +

    'TJvCheckTreeView=TreeView'#13#10 +
    'TJvDBTreeView=TreeView'#13#10 +
    'TJvJanTreeView=TreeView'#13#10 +
    'TJvPageListTreeView=TreeView'#13#10 +
    'TJvSettingsTreeView=TreeView'#13#10 +
    'TJvTreeView=TreeView'#13#10 +
    'TJvRegistryTreeView=TreeView'#13#10 +

    'TJvDBComboBox=ComboBox'#13#10 +
    'TJvDBSearchComboBox=ComboBox'#13#10 +
    'TJvDBIndexCombo=ComboBox'#13#10 +
    'TJvCSVComboBox=ComboBox'#13#10 +
    'TJvComboBox=ComboBox'#13#10 +
    'TJvHTComboBox=ComboBox'#13#10 +
    'TJvUninstallComboBox=ComboBox'#13#10 +

    'TJvPageControl=PageControl'#13#10 +

    'TJvTabControl=TabControl'#13#10 +
    
    'TJvDBGridFooter=StatusBar'#13#10 +
    'TJvStatusBar=StatusBar'#13#10 +

    'TJvScrollBox=ScrollControl'#13#10 +

    'TJvUpDown=UpDownBtn'#13#10 +
    'TJvDomainUpDown=UpDownBtn'#13#10 +

    'TJvScrollBar=TScrollBar',
  // 9. TMS Edits
    'TAdvStringGrid=Grid'#13#10 +
    'TDBAdvGrid=Grid'#13#10 +
    'TDBLUEdit=Edit'#13#10 +
    'TAdvSpinEdit=Edit'#13#10 +
    'TAdvLUEdit=Edit'#13#10 +
    'TAdvEditBtn=Edit'#13#10 +
    'TUnitAdvEditBtn=Edit'#13#10 +
    'TAdvFileNameEdit=Edit'#13#10 +
    'TAdvDirectoryEdit=Edit'#13#10 +
    'TDBAdvLUEdit=Edit'#13#10 +
    'TDBAdvSpinEdit=Edit'#13#10 +
    'TDBAdvEdit=Edit'#13#10 +
    'TDBAdvMaskEdit=Edit'#13#10 +
    'TEditBtn=Edit'#13#10 +
    'TUnitEditBtn=Edit'#13#10 +
    'TMoneyEdit=Edit'#13#10 +
    'TDBMoneyEdit=Edit'#13#10 +
    'TMaskEditEx=Edit'#13#10 +
    'TEditListBox=Edit'#13#10 +
    'TAdvEdit=Edit'#13#10 +
    'TAdvMaskEdit=Edit'#13#10 +
    'TLUEdit=Edit'#13#10 +
    'TDBAdvEditBtn=Edit'#13#10 +
    'TAdvMoneyEdit=Edit'#13#10 +
    'TDBAdvMoneyEdit=Edit'#13#10 +
    'THTMListBox=Edit'#13#10 +
    'THTMLCheckList=Edit'#13#10 +
    'TParamListBox=Edit'#13#10 +
    'TParamCheckList=Edit'#13#10 +
    'THTMLTreeview=TreeView'#13#10 +
    'TParamTreeview=TreeView'#13#10 +
    'TDBLUCombo=ComboBox'#13#10 +
    'TAdvComboBox=ComboBox'#13#10 +
    'TAdvListView=ListView'#13#10 +
    'TLUCombo=ComboBox'#13#10 +
    'TAdvDBLookupComboBox=ComboBox'#13#10 +
    'TAdvTreeComboBox=ComboBox'#13#10 +
    'THTMLComboBox=ComboBox'#13#10 +
    'TCheckListEdit=wwEdit',
  // 10. SynEdits
    'TSynEdit=Edit'#13#10 +
    'TSynMemo=Edit'#13#10 +
    'TDBSynEdit=Edit',
  // 11. mxEdits
    '',
  // 12. RichViews
    'TRichView=Grid'#13#10 +
    'TRVPrintPreview=Edit'#13#10 +
    'TSRVPageScroll=Edit'#13#10 +
    'TRVSpinEdit=Edit'#13#10 +
    'TDBRichViewEdit=Grid'#13#10 +
    'TRichViewEdit=Grid'#13#10 +
    'TDBRichView=Grid'#13#10,
  // 13. Raize
    'TRzTreeView=TreeView'#13#10 +
    'TRzEdit=Edit'#13#10 +
    'TRzHotKeyEdit=Edit'#13#10 +
    'TRzMaskEdit=Edit'#13#10 +
    'TRzNumericEdit=Edit'#13#10 +
    'TRzExpandEdit=Edit'#13#10 +
    'TRzMemo=Edit'#13#10 +
    'TRzListBox=Edit'#13#10 +
    'TRzRankListBox=Edit'#13#10 +
    'TRzTabbedListBox=Edit'#13#10 +
    'TRzCheckList=Edit'#13#10 +
    'TRzEditListBox=Edit'#13#10 +
    'TRzCheckTree=TreeView'#13#10 +
    'TRzRichEdit=Edit'#13#10 +
    'TRzShellTree=TreeView'#13#10 +
    'TRzGroupBox=GroupBox'#13#10 +
    'TRzListView=ListView'#13#10 +
    'TRzShellList=ListView'#13#10 +
    'TRzPanel=Panel'#13#10 +
    'TRzComboBox=ComboBox'#13#10 +
    'TRzImageComboBox=ComboBox'#13#10 +
    'TRzMRUComboBox=ComboBox'#13#10 +
    'TRzShellCombo=ComboBox'#13#10 +
    'TRzDateTimeEdit=wwEdit'
  );

implementation

{$R *.dfm}

uses sDefaults, ac3dNewClass, acntUtils, IniFiles, sStoreUtils;

procedure TForm3rdPartyEditor.Populate(ControlRepaint : boolean = True);
var
  i, j : integer;
begin
  if ControlRepaint then sListView1.Items.BeginUpdate;
  sListView1.Items.Clear;
  for j := 0 to Length(SM.ThirdLists) - 1 do begin
    for i := 0 to SM.ThirdLists[j].Count - 1 do if (SM.ThirdLists[j][i] <> ' ') then begin
      sListView1.Items.Add;
      sListView1.Items[sListView1.Items.Count - 1].Caption := SM.ThirdLists[j][i];
      sListView1.Items[sListView1.Items.Count - 1].SubItems.Add(acThirdCaptions[j]);
      sListView1.Items[sListView1.Items.Count - 1].ImageIndex := j;
    end;
  end;
  if ControlRepaint then begin
    sListView1.Items.EndUpdate;
    RedrawWindow(sListView1.Handle, nil, 0, RDW_UPDATENOW or RDW_ERASE or RDW_INVALIDATE);
  end;
end;

procedure TForm3rdPartyEditor.sBitBtn2Click(Sender: TObject);
begin
  FormNewThirdClass := TFormNewThirdClass.Create(Application);
  FormNewThirdClass.sEdit1.Text := 'T';
  FormNewThirdClass.ShowModal;
  if FormNewThirdClass.ModalResult = mrOk then begin
    SM.ThirdLists[FormNewThirdClass.sComboBox1.ItemIndex].Add(FormNewThirdClass.sEdit1.Text);
    UpdateThirdNames(SM);
    Populate;
  end;
  FreeAndNil(FormNewThirdClass);
end;

procedure TForm3rdPartyEditor.sBitBtn1Click(Sender: TObject);
begin
  Close
end;

procedure TForm3rdPartyEditor.FormShow(Sender: TObject);
begin
  sListView1.Columns[1].Width := 150;
end;

procedure TForm3rdPartyEditor.sBitBtn3Click(Sender: TObject);
var
  i, j : integer;
{$IFDEF DELPHI6UP}
  LastIndex : integer;
{$ENDIF}
begin
{$IFDEF DELPHI6UP}
  LastIndex := sListView1.ItemIndex;
{$ENDIF}
  for i := 0 to sListView1.Items.Count - 1 do if sListView1.Items[i].Selected then begin
    j := 0;
    while j < SM.ThirdLists[sListView1.Items[i].ImageIndex].Count do begin
      if SM.ThirdLists[sListView1.Items[i].ImageIndex][j] = sListView1.Items[i].Caption then begin
        SM.ThirdLists[sListView1.Items[i].ImageIndex].Delete(j);
        if SM.ThirdLists[sListView1.Items[i].ImageIndex].Count = 0 then SM.ThirdLists[sListView1.Items[i].ImageIndex].Text := ' ';
      end
      else inc(j);
    end;
  end;
  UpdateThirdNames(SM);
  Populate;
{$IFDEF DELPHI6UP}
  if LastIndex > sListView1.Items.Count - 1 then sListView1.ItemIndex := sListView1.Items.Count - 1 else sListView1.ItemIndex := LastIndex;
{$ENDIF}
end;

procedure TForm3rdPartyEditor.sBitBtn4Click(Sender: TObject);
begin
  LoadThirdNames(SM, True);
  Populate;
end;

procedure TForm3rdPartyEditor.sCheckBox1Click(Sender: TObject);
var
  i : integer;
begin
  TsCheckBox(Sender).Checked := boolean(TsCheckBox(Sender).Tag);
  sListBox2.Items.BeginUpdate;
  for i := 0 to sListBox2.Items.Count - 1 do
    if sListBox2.ItemEnabled[i] then sListBox2.Checked[i] := boolean(TsCheckBox(Sender).Tag);
  sListBox2.Items.EndUpdate;
end;

procedure TForm3rdPartyEditor.sSpeedButton1Click(Sender: TObject);
var
  j, Ndx : integer;
begin
  FormNewThirdClass := TFormNewThirdClass.Create(Application);
  Ndx := {$IFDEF DELPHI6UP}sListView1.ItemIndex{$ELSE}sListView1.Selected.Index{$ENDIF};
  FormNewThirdClass.sEdit1.Text := sListView1.Items[Ndx].Caption;
  FormNewThirdClass.sComboBox1.ItemIndex := FormNewThirdClass.sComboBox1.IndexOf(sListView1.Items[Ndx].SubItems[0]);
  FormNewThirdClass.Caption := 'Edit';
  FormNewThirdClass.ShowModal;
  if FormNewThirdClass.ModalResult = mrOk then begin
    j := 0;
    while j < SM.ThirdLists[sListView1.Items[Ndx].ImageIndex].Count do begin
      if SM.ThirdLists[sListView1.Items[Ndx].ImageIndex][j] = sListView1.Items[Ndx].Caption then begin
        SM.ThirdLists[sListView1.Items[Ndx].ImageIndex].Delete(j);
      end
      else inc(j);
    end;
    SM.ThirdLists[FormNewThirdClass.sComboBox1.ItemIndex].Add(FormNewThirdClass.sEdit1.Text);
    UpdateThirdNames(SM);
    Populate;
  end;
  FreeAndNil(FormNewThirdClass);
end;

procedure TForm3rdPartyEditor.sListView1Change(Sender: TObject; Item: TListItem; Change: TItemChange);
begin
  sSpeedButton1.Enabled := sListView1.Selected <> nil;
  Delete1.Enabled := sSpeedButton1.Enabled;
  Edit1.Enabled := sSpeedButton1.Enabled;
end;

type
  TAccessListbox = class(TsCheckListBox);

procedure TForm3rdPartyEditor.sListBox1Click(Sender: TObject);
  procedure ShowSupportedControls;
  var
    sl : TStringList;
    i, j{$IFDEF ALITE}, d, c{$ENDIF} : integer;
    s1, s2 : string;
  begin
    sListBox2.Sorted := False;
    sListBox2.SkinData.BeginUpdate;
    sListBox2.Items.BeginUpdate;
    sListBox2.Items.Clear;

    sl := TStringList.Create;
    sl.Text := acCtrlsArray[sListBox1.ItemIndex];

    for i := 0 to sl.Count - 1 do begin
      s1 := acntUtils.ExtractWord(1, sl[i], ['=']); // Name of type
      s2 := acntUtils.ExtractWord(2, sl[i], ['=']); // Rule of skinning

      // Add new value
      for j := 0 to Length(acThirdCaptions) - 1 do if acThirdCaptions[j] = s2 then begin
{$IFDEF ALITE}
        d := 1;
        for c := 0 to Length(acLiteCtrls) - 1 do begin
          if s1 = acLiteCtrls[c] then begin
            // Type was found
            d := 0;
          end;
        end;
        sListBox2.Items.AddObject(s1, TObject(d));
{$ELSE}
        sListBox2.Items.Add(s1);
{$ENDIF}
        Break;
      end;
    end;
    sListBox2.Items.EndUpdate;
    sListBox2.Items.BeginUpdate;

    sListBox2.Sorted := True;

    for i := 0 to sListBox2.Items.Count - 1 do begin
{$IFDEF ALITE}
      if (sListBox1.ItemIndex <> 0) or (TAccessListbox(sListBox2).GetItemData(i) = 1) then begin
        sListBox2.ItemEnabled[i] := False;
      end
      else
{$ENDIF}
      sListBox2.Checked[i] := True
    end;
    sl.Free;
    sListBox2.Items.EndUpdate;
    sListBox2.SkinData.EndUpdate;
  end;
begin
  ShowSupportedControls;
  sSpeedButton2.Enabled := {$IFNDEF ALITE}sListBox1.ItemIndex >= 0{$ELSE}sListBox1.ItemIndex = 0{$ENDIF};
  sSpeedButton3.Enabled := sSpeedButton2.Enabled;
  SelectCtrls(sListBox1.ItemIndex);
end;

procedure TForm3rdPartyEditor.sSpeedButton2Click(Sender: TObject);
var
  sl : TStringList;
  i, j, k, l : integer;
  s1, s2 : string;
begin
  sl := TStringList.Create;
  sl.Text := acCtrlsArray[sListBox1.ItemIndex];
  for i := 0 to sl.Count - 1 do begin
    s1 := acntUtils.ExtractWord(1, sl[i], ['=']); // Name of type
    s2 := acntUtils.ExtractWord(2, sl[i], ['=']); // Rule of skinning
    // Delete if exists already
    for j := 0 to Length(SM.ThirdLists) - 1 do begin
      k := 0;
      while k < SM.ThirdLists[j].Count do begin
        if (SM.ThirdLists[j][k] = s1)
          then SM.ThirdLists[j].Delete(k)
          else inc(k);
      end;
    end;
    // Add new value
    for j := 0 to Length(acThirdCaptions) - 1 do if acThirdCaptions[j] = s2 then begin
      l := sListBox2.Items.IndexOf(s1);
      if (l > -1) and (sListBox2.Checked[l]) then begin
        if SM.ThirdLists[j].Text = ' '#13#10
          then SM.ThirdLists[j].Text := s1
          else SM.ThirdLists[j].Add(s1);
      end;
      Break;
    end
  end;
  sl.Free;
  UpdateThirdNames(SM);
  Populate;
  SelectCtrls(sListBox1.ItemIndex);
end;

procedure TForm3rdPartyEditor.sListView1ColumnClick(Sender: TObject; Column: TListColumn);
begin
  if Column.Index = 0 then sListView1.SortType := stText else sListView1.SortType := stData;
  Populate;
end;

procedure TForm3rdPartyEditor.sListView1DblClick(Sender: TObject);
begin
  if sSpeedButton1.Enabled then sSpeedButton1.Click;
end;

procedure TForm3rdPartyEditor.sSpeedButton3Click(Sender: TObject);
var
  sl : TStringList;
  i, j, k : integer;
  s1, s2 : string;
begin
  sl := TStringList.Create;
  sl.Text := acCtrlsArray[sListBox1.ItemIndex];

  for i := 0 to sl.Count - 1 do begin
    s1 := acntUtils.ExtractWord(1, sl[i], ['=']); // Name of type
    s2 := acntUtils.ExtractWord(2, sl[i], ['=']); // Rule of skinning

    // Delete if exists already
    for j := 0 to Length(SM.ThirdLists) - 1 do begin
      k := 0;
      while k < SM.ThirdLists[j].Count do begin
        if (SM.ThirdLists[j][k] = s1) then SM.ThirdLists[j].Delete(k) else inc(k);
      end;
    end;
  end;

  sl.Free;
  UpdateThirdNames(SM);
  Populate;
end;

procedure TForm3rdPartyEditor.SelectCtrls(TypeIndex: integer);
var
  sl : TStringList;
  i, j : integer;
  s1 : string;
begin
  sl := TStringList.Create;
  sl.Text := acCtrlsArray[TypeIndex];

  for j := 0 to sListView1.Items.Count - 1 do sListView1.Items[j].Selected := False;

  for i := 0 to sl.Count - 1 do begin
    s1 := acntUtils.ExtractWord(1, sl[i], ['=']); // Name of type
    // Search
    for j := 0 to sListView1.Items.Count - 1 do if sListView1.Items[j].Caption = s1 then begin
      sListView1.Items[j].Selected := True;
      Break;
    end;
  end;

  sl.Free;
end;

const
  s_ThirdParty = 'ThirdParty';

procedure TForm3rdPartyEditor.sSpeedButton4Click(Sender: TObject);
var
  i, j : integer;
  iFile : TMeminiFile;
  s1, s2 : string;
begin
  if SaveDialog1.Execute then begin
    iFile := TMeminiFile.Create(SaveDialog1.FileName);
    for j := 0 to Length(SM.ThirdLists) - 1 do begin
      for i := 0 to SM.ThirdLists[j].Count - 1 do if (SM.ThirdLists[j][i] <> ' ') then begin
        s1 := SM.ThirdLists[j][i];
        s2 := acThirdCaptions[j];
        WriteIniStr(s_ThirdParty, s1, s2, iFile);
      end;
    end;
    iFile.UpdateFile;
    iFile.Free;
  end;
end;

procedure TForm3rdPartyEditor.sSpeedButton5Click(Sender: TObject);
var
  i, j : integer;
  iFile : TMeminiFile;
  s1, s2 : string;
  sl : TStringList;
begin
  if OpenDialog1.Execute then begin
    iFile := TMeminiFile.Create(OpenDialog1.FileName);
    for j := 0 to Length(SM.ThirdLists) - 1 do SM.ThirdLists[j].Clear;
    sl := TStringList.Create;
    iFile.ReadSection(s_ThirdParty, sl);
    for i := 0 to sl.Count - 1 do begin
      s1 := sl[i];
      s2 := ReadIniString(s_ThirdParty, s1, iFile);

      for j := 0 to Length(acThirdCaptions) - 1 do if acThirdCaptions[j] = s2 then begin
        SM.ThirdLists[j].Add(s1);
        Break;
      end;
    end;
    iFile.Free;
  end;
  Populate;
end;

procedure TForm3rdPartyEditor.sSpeedButton6Click(Sender: TObject);
var
  j : integer;
begin
  for j := 0 to Length(SM.ThirdLists) - 1 do SM.ThirdLists[j].Clear;
  Populate;
end;

procedure TForm3rdPartyEditor.FormCreate(Sender: TObject);
{$IFDEF ALITE}
var
  s : string;
  i : integer;
{$ENDIF}
begin
{$IFDEF ALITE}
  sBitBtn2.Enabled := False;
  Addnew1.Enabled := False;
  sBitBtn2.Hint := 'Feature is not available for the package Lite Edition';
  sBitBtn4.Enabled := False;
  sBitBtn4.Hint := sBitBtn2.Hint;
  sSpeedButton4.Enabled := False;
  sSpeedButton4.Hint := sBitBtn2.Hint;
  sSpeedButton5.Enabled := False;
  sSpeedButton5.Hint := sBitBtn2.Hint;

  s := acLiteCtrls[0];
  for i := 1 to Length(acLiteCtrls) - 1 do begin
    s := s + ', ' + acLiteCtrls[i];
  end;

  ShowMessage('List of supported standard controls for the Lite Edition is limited by these types of skinning : '#13#10 + s);
{$ENDIF}
end;

procedure TForm3rdPartyEditor.Edit1Click(Sender: TObject);
begin
  sSpeedButton1.Click
end;

end.
