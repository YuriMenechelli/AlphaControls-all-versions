unit acNoteBook;
{$I sDefs.inc}
{.$DEFINE LOGGED}

interface

uses Messages, Windows, SysUtils, Classes, Controls, Forms, Menus, Graphics, {$IFNDEF DELPHI5}types,{$ENDIF}
  StdCtrls, sCommonData, ExtCtrls, acSBUtils{$IFDEF LOGGED}, sDebugMsgs{$ENDIF};

type
{$IFNDEF NOTFORHELP}
  TacWndArray = array of TacMainWnd;
  TsPage = class(TPage); // For compatibility with old version
{$ENDIF}

  TsNotebook = class(TNoteBook)
{$IFNDEF NOTFORHELP}
  private
    FCommonData: TsCommonData;
    wa : TacWndArray;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AfterConstruction; override;
    procedure Loaded; override;
    procedure WndProc(var Message: TMessage); override;
  published
    property Align;
    property Anchors;
    property Color;
    property Ctl3D;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Font;
    property Enabled;
    property Constraints;
    property ParentColor;
    property ParentCtl3D;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Visible;
    property OnClick;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDock;
    property OnStartDrag;
{$ENDIF}
    property SkinData : TsCommonData read FCommonData write FCommonData;
  end;

implementation

uses Consts, sConst, sMessages, sVclUtils, sGraphUtils, sAlphaGraph, sStyleSimply, acntUtils;

{ TsNotebook }

constructor TsNotebook.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCommonData := TsCommonData.Create(Self, True);
  FCommonData.COC := COC_TsCheckBox;
end;

destructor TsNotebook.Destroy;
var
  i : integer;
begin
  if Assigned(FCommonData) then FreeAndNil(FCommonData);
  for i := 0 to Length(wa) - 1 do if (wa[i] <> nil) and wa[i].Destroyed then FreeAndNil(wa[i]);
  inherited Destroy;
end;

procedure TsNotebook.AfterConstruction;
begin
  inherited;
  FCommonData.Loaded;
end;

procedure TsNotebook.Loaded;
begin
  inherited;
  FCommonData.Loaded;
end;

type
  TacPageWnd = class(TacMainWnd)
  protected
    Notebook : TsNotebook;
    Page : TPage;
  public
 	function PrepareCache : boolean;
 	//procedure PrepareCache;
	procedure AC_WMPaint(Message : TWMPaint);
	procedure acWndProc(var Message: TMessage); override;
  end;

var
  bFlag : boolean = False;

procedure TsNotebook.WndProc(var Message: TMessage);
var
  i : integer;
  Page : TPage;
begin
{$IFDEF LOGGED}
  AddToLog(Message);
{$ENDIF}
  if Message.Msg = SM_ALPHACMD then case Message.WParamHi of
    AC_CTRLHANDLED : begin Message.Result := 1; Exit end;
    AC_GETAPPLICATION : begin Message.Result := LRESULT(Application); Exit end;
    AC_REMOVESKIN : begin
      for i := 0 to ControlCount - 1 do if Controls[i] is TPage then SendMessage(TPage(Controls[i]).Handle, Message.Msg, Message.WParam, Message.LParam);
      if (ACUInt(Message.LParam) = ACUInt(SkinData.SkinManager)) then begin
        CommonWndProc(Message, FCommonData);
        RedrawWindow(Handle, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_UPDATENOW or RDW_NOERASE or RDW_ALLCHILDREN);
      end;
      exit
    end;
    AC_SETNEWSKIN : begin
      if (ACUInt(Message.LParam) = ACUInt(SkinData.SkinManager)) then CommonWndProc(Message, FCommonData);
      for i := 0 to ControlCount - 1 do if Controls[i] is TPage then SendMessage(TPage(Controls[i]).Handle, Message.Msg, Message.WParam, Message.LParam);
      Exit
    end;
    AC_REFRESH : begin
      if (ACUInt(Message.LParam) = ACUInt(SkinData.SkinManager)) then begin
        CommonWndProc(Message, FCommonData);
        RedrawWindow(Handle, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_ERASE or RDW_ALLCHILDREN);
      end;
      for i := 0 to ControlCount - 1 do if Controls[i] is TPage then SendMessage(TPage(Controls[i]).Handle, Message.Msg, Message.WParam, Message.LParam);
      Exit
    end;
    AC_GETBG : begin
      GetBGInfo(PacBGInfo(Message.LParam), Parent);
      inc(PacBGInfo(Message.LParam)^.Offset.X, Left);
      inc(PacBGInfo(Message.LParam)^.Offset.Y, Top);
      Exit;
    end;
    AC_GETCONTROLCOLOR : if SkinData.FOwnerControl <> nil then begin
      CommonMessage(Message, SkinData);
      Exit;
    end;
  end;
  case Message.Msg of
    WM_PARENTNOTIFY : begin
      case Message.WParamLo of
        WM_CREATE : for i := 0 to ControlCount - 1 do if (Self.Controls[i] is TPage) and (TPage(Controls[i]).Handle = THandle(Message.LParam)) then begin
          Page := TPage(Controls[i]);
          SetLength(wa, Length(wa) + 1);
          wa[Length(wa) - 1] := TacPageWnd.Create(Page.Handle, nil, SkinData.SkinManager, SkinData.SkinSection);
          wa[Length(wa) - 1].SkinData.FOwnerControl := Page;
          TacPageWnd(wa[Length(wa) - 1]).Notebook := Self;
          TacPageWnd(wa[Length(wa) - 1]).Page := Page;
          AddToAdapter(Self);
          Break;
        end;
      end;
    end;
  end;

  if not ControlIsReady(Self) or (FCommonData = nil) or not FCommonData.Skinned then inherited else begin
    if Message.Msg = SM_ALPHACMD then begin
      case Message.WParamHi of
        AC_ENDPARENTUPDATE : if FCommonData.Updating then begin
          FCommonData.Updating := False;
          for i := 0 to ControlCount - 1 do if Controls[i] is TPage then SendMessage(TPage(Controls[i]).Handle, Message.Msg, Message.WParam, Message.LParam);
        end;
        AC_PREPARING : begin
          Message.Result := integer(FCommonData.FUpdating);
          Exit;
        end;
        AC_URGENTPAINT : begin
          CommonWndProc(Message, FCommonData);
          if FCommonData.UrgentPainting then begin
            InitCacheBmp(FCommonData);
            FCommonData.BGChanged := False;
          end;
        end
        else CommonMessage(Message, FCommonData);
      end;
    end
    else begin
      case Message.Msg of
        CM_SHOWINGCHANGED, CM_VISIBLECHANGED : begin
          inherited;
          exit;
        end;
        WM_ERASEBKGND : if not bFlag then begin
          bFlag := True;
          if (PageIndex >= 0) and (PageIndex < Length(wa)) then begin
            Message.Result := SendMessage(wa[PageIndex].CtrlHandle, Message.Msg, Message.WParam, 1);
            Exit;
          end;
          bFlag := False;
        end;
      end;
      CommonWndProc(Message, FCommonData);
      inherited;
    end;
  end;
end;

{ TacPageWnd }

procedure TacPageWnd.AC_WMPaint(Message: TWMPaint);
var
  PS : TPaintStruct;
  DC : hdc;
  cRect : TRect;
  i : integer;
begin
  InitCtrlData(CtrlHandle, ParentWnd, WndRect, ParentRect, WndSize, WndPos);

  if (csPaintCopy in Page.ControlState) and (Message.Msg = WM_ERASEBKGND) then begin
    if not SkinData.Updating then begin
      PrepareCache;
      BitBlt(Message.DC, 0, 0, WndSize.cx, WndSize.cy, SkinData.FCacheBmp.Canvas.Handle, 0, 0, SRCCOPY);
    end;
  end
  else begin
    if not InAnimationProcess and (Message.Msg <> WM_ERASEBKGND) then BeginPaint(CtrlHandle, ps);
    SkinData.FUpdating := SkinData.Updating;
    if not SkinData.FUpdating then begin
      if (Message.DC = 0) or (Message.Unused <> 1)
        then DC := GetWindowDC(CtrlHandle)
        else DC := Message.DC;
      PrepareCache;
      if DlgMode then begin
        cRect.Top := SkinData.SkinManager.MaskWidthTop(SkinData.BorderIndex);
        cRect.Left := SkinData.SkinManager.MaskWidthLeft(SkinData.BorderIndex);
        cRect.Right := WndSize.cx - SkinData.SkinManager.MaskWidthRight(SkinData.BorderIndex);
        cRect.Bottom := WndSize.cy - SkinData.SkinManager.MaskWidthBottom(SkinData.BorderIndex);

        ExcludeClipRect(DC, cRect.Left, cRect.Top, cRect.Right, cRect.Bottom);
      end;
      if (Page = nil) then CopyHwndCache(CtrlHandle, SkinData, Rect(0, 0, 0, 0), Rect(0, 0, WndSize.cx, WndSize.cy), DC, False) else begin
        for i := 0 to Page.ControlCount - 1 do if Page.Controls[i] is TWinControl then Page.Controls[i].ControlStyle := Page.Controls[i].ControlStyle + [csOpaque];
        CopyWinControlCache(Page, SkinData, Rect(0, 0, 0, 0), Rect(0, 0, WndSize.cx, WndSize.cy), DC, False);
      end;
      PaintControls(DC, Page, False, Point(0, 0));
      if (Message.DC = 0) or (Message.Unused <> 1) then ReleaseDC(CtrlHandle, DC);
      SetParentUpdated(CtrlHandle);
    end;
    if not InAnimationProcess and (Message.Msg <> WM_ERASEBKGND) then EndPaint(CtrlHandle, ps);
  end;
end;

procedure TacPageWnd.acWndProc(var Message: TMessage);
var
  i : integer;
begin
  if Message.Msg = SM_ALPHACMD then case Message.WParamHi of
    AC_CTRLHANDLED : begin Message.Result := 1; Exit end;
    AC_SETNEWSKIN : begin
      if (ACUInt(Message.LParam) = ACUInt(SkinData.SkinManager)) then CommonWndProc(Message, SkinData);
      AlphaBroadCastCheck(Skindata.FOwnerControl, CtrlHandle, Message);
      Exit;
    end;
  end;
  if SkinData.Skinned then begin
    if Message.Msg = SM_ALPHACMD then case Message.WParamHi of
      AC_REMOVESKIN : begin
        if (ACUInt(Message.LParam) = ACUInt(SkinData.SkinManager)) then begin
          CommonWndProc(Message, SkinData);
          RedrawWindow(Page.Handle, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_UPDATENOW or RDW_NOERASE or RDW_ALLCHILDREN);
        end;
        AlphaBroadCastCheck(Skindata.FOwnerControl, CtrlHandle, Message);
        Exit;
      end;
      AC_REFRESH : begin
        if (ACUInt(Message.LParam) = ACUInt(SkinData.SkinManager)) then begin
          CommonWndProc(Message, SkinData);
        end;
        AlphaBroadCastCheck(Skindata.FOwnerControl, CtrlHandle, Message);
      end;
      AC_CHILDCHANGED : begin
        CommonMessage(Message, SkinData);
        Exit;
      end;
	  AC_GETBG : 
		if (SkinData.SkinManager <> nil) and SkinData.SkinManager.IsValidSkinIndex(SkinData.SkinIndex) then
		begin
			InitBGInfo(SkinData, PacBGInfo(Message.LParam), 0);
			if (PacBGInfo(Message.LParam)^.BgType = btNotReady) or (PacBGInfo(Message.LParam)^.BgType = btFill) then Exit; 
			
			if SkinData.BGChanged and ((SkinData.FCacheBmp.Width <> NoteBook.Width) or (SkinData.FCacheBmp.Height <> NoteBook.Height)) and not SkinData.Updating then
			begin
				if (NoteBook.Parent = nil) or not NoteBook.Parent.HandleAllocated or GetBoolMsg(NoteBook.Parent.Handle, ac_CtrlHandled) then 
				begin // If parent is skinned
					PacBGInfo(Message.LParam)^.BgType := btNotReady;
					Exit;
				end;
			end;
		Exit;		
        end;
    AC_ENDPARENTUPDATE : begin
		if not InUpdating(SkinData, True) then begin
		RedrawWindow(Notebook.Handle, nil, 0, RDW_INVALIDATE or RDW_FRAME);// or RDW_UPDATENOW or RDW_ERASE);
		//          SendMessage(CtrlHandle, WM_PAINT, 0, 0);
		//          SendMessage(CtrlHandle, WM_NCPAINT, 0, 0);
		//          for i := 0 to TWincontrol(Skindata.FOwnerControl).ControlCount - 1 do if TWincontrol(Skindata.FOwnerControl).Controls[i] is TWinControl then SendMessage(TWinControl(TWincontrol(Skindata.FOwnerControl).Controls[i]).Handle, Message.Msg, Message.WParam, Message.LParam);
		end;
		SetParentUpdated(Notebook);	        
      end;
      AC_PREPARING : begin
        Message.Result := integer(Notebook.SkinData.FUpdating);
        Exit;
      end;
      AC_GETCONTROLCOLOR : begin
        CommonMessage(Message, SkinData);
        Exit;
      end
      else if CommonMessage(Message, SkinData) then Exit;
    end;
    case Message.Msg of
      WM_ERASEBKGND : if not DlgMode then begin
        AC_WMPaint(TWMPaint(Message));
        Message.Result := 1;
        Exit;
      end;
      WM_NCPAINT : if DlgMode then begin
        AC_WMPaint(TWMPaint(MakeMessage(WM_NCPAINT, 0, 0, 0)));
        Exit;
      end;
      WM_PRINT : if not DlgMode then begin
        SkinData.BGChanged := True;
        Message.LParam := 1;
        AC_WMPaint(TWMPaint(Message));
      end;
      WM_PAINT : if not DlgMode then begin
        AC_WMPaint(TWMPaint(Message));
        Exit;
      end;
      WM_SIZE, WM_MOVE : SkinData.BGChanged := True;
      WM_PARENTNOTIFY : if (Message.WParam and $FFFF = WM_CREATE) or (Message.WParam and $FFFF = WM_DESTROY) then begin
        inherited;
        if (Message.WParamLo = WM_CREATE) and Assigned(Notebook) then AddToAdapter(Notebook);
        exit;
      end;
    end;
  end;
  inherited;
end;

function TacPageWnd.PrepareCache : boolean;
var
  ParentBG : TacBGInfo;
  CI : TCacheInfo;
begin
  InitCacheBmp(SkinData);
  SkinData.FCacheBmp.Width := WndSize.cx;
  SkinData.FCacheBmp.Height := WndSize.cy;
  
  ParentBG.Bmp := nil;
  ParentBG.BgType := btUnknown;
  ParentBG.PleaseDraw := False;
  GetBGInfo(@ParentBG, NoteBook.Parent);
  
  if ParentBg.BgType = btNotReady then begin
	SkinData.FUpdating := True;
	Result := False;
	Exit;
  end;
  Result := True;  
  
  CI := BGInfoToCI(@ParentBG);

  PaintItem(SkinData, CI, False, 0, Rect(0, 0, WndSize.cx, WndSize.cy), Point(Notebook.Left, Notebook.Top), SkinData.FCacheBMP, True);

  SkinData.BGChanged := False;
end;

initialization
    Classes.RegisterClasses([TsPage]); // For compatibility with old version

finalization

end.
