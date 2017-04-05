unit acHeaderControl;
{$I sDefs.inc}
{.$DEFINE LOGGED}

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, {$IFDEF DELPHI7UP}Types, {$ENDIF}Forms, Dialogs,
  ComCtrls, sCommonData{$IFDEF LOGGED}, sDebugMsgs{$ENDIF};

type
  TsHeaderControl = class(THeaderControl)
{$IFNDEF NOTFORHELP}
  private
    FCommonData: TsCommonData;
  protected
    CurItem : integer;
    PressedItem : integer;
    IndexLeft : integer;
    IndexRight : integer;
    IndexAlone : integer;
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
    procedure WMNCPaint(var Message: TMessage); message WM_NCPAINT;
    procedure PrepareCache;
    procedure PaintItems;
    procedure WndProc (var Message: TMessage); override;
    function GetItemUnderMouse(p: TPoint): integer;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Loaded; override;
    procedure AfterConstruction; override;
  published
{$ENDIF}
    property SkinData : TsCommonData read FCommonData write FCommonData;
  end;

implementation

uses Commctrl, sGraphUtils, acntUtils, sMessages, sVCLUtils, sConst, sSkinProps;

{ TsHeaderControl }

procedure TsHeaderControl.AfterConstruction;
begin
  inherited;
  FCommonData.Loaded;
  if FCommonData.SkinManager <> nil then begin
    IndexLeft := FCommonData.SkinManager.GetSkinIndex(s_ColHeaderL);
    IndexRight := FCommonData.SkinManager.GetSkinIndex(s_ColHeaderR);
    IndexAlone := FCommonData.SkinManager.GetSkinIndex(s_ColHeaderA);
  end;
end;

constructor TsHeaderControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCommonData := TsCommonData.Create(Self, True);
  FCommonData.COC := COC_TsHeaderControl;
  CurItem := -1;
  PressedItem := -1;
end;

destructor TsHeaderControl.Destroy;
begin
  if Assigned(FCommonData) then FreeAndNil(FCommonData);
  inherited Destroy;
end;

function TsHeaderControl.GetItemUnderMouse(p: TPoint): integer;
var
  i : integer;
  R : TRect;
begin
  Result := -1;
  for i := 0 to Sections.Count - 1 do begin
    R := Rect(Sections[i].Left, BorderWidth, Sections[i].Right, Height - BorderWidth);
    if PtInRect(R, p) then begin
      Result := i;
      Exit;
    end;
  end;
end;

procedure TsHeaderControl.Loaded;
begin
  inherited;
  FCommonData.Loaded;
  if FCommonData.SkinManager <> nil then begin
    IndexLeft := FCommonData.SkinManager.GetSkinIndex(s_ColHeaderL);
    IndexRight := FCommonData.SkinManager.GetSkinIndex(s_ColHeaderR);
    IndexAlone := FCommonData.SkinManager.GetSkinIndex(s_ColHeaderA);
  end;
end;

procedure TsHeaderControl.PaintItems;
const
  Margin = 5;
  Spacing = 10;
var
  i, si, Ndx, ImgW, allw, Index : integer;
  CI : TCacheInfo;
  State : integer;
  s, ss, NewText : acString;
  TempBmp : TBitmap;
  R, TextRC, ItemRC : TRect;
  TextSize : TSize;
  Section : THeaderSection;
begin
  s := s_ColHeader;
  Ndx := FCommonData.SkinManager.GetSkinIndex(s);
  if not FCommonData.SkinManager.IsValidSkinIndex(Ndx) then begin
    s := s_Button;
    Ndx := FCommonData.SkinManager.GetSkinIndex(s);
  end;

  CI := MakeCacheInfo(FCommonData.FCacheBmp);
  TempBmp := nil;
  for i := 0 to Self.Sections.Count - 1 do begin
    Index := Header_OrderToIndex(Handle, i);
    Section := Sections[i];
    if Section.AllowClick then begin
      if i = PressedItem then State := 2 else if i = CurItem then State := 1 else State := 0;
    end
    else State := 0;

    Header_GetItemRect(Handle, Index, @ItemRc);

    TempBmp := CreateBmp32(WidthOf(ItemRc), Height - 2 * BorderWidth);
    R := Rect(0, 0, TempBmp.Width, TempBmp.Height);

    if (i = 0) and (i = Sections.Count - 1) and (IndexAlone <> -1) then begin
      si := IndexAlone;
      ss := s_ColHeaderA;
    end
    else if (i = 0) and (IndexLeft <> -1) then begin
      si := IndexLeft;
      ss := s_ColHeaderL;
    end
    else if (i = Sections.Count - 1) and (IndexRight <> -1) then begin
      si := IndexRight;
      ss := s_ColHeaderR;
    end
    else begin
      si := Ndx;
      ss := s;
    end;

    PaintItem(si, ss, CI, True, State, R, Point(ItemRc.Left + BorderWidth, BorderWidth), TempBmp, FCommonData.SkinManager);

    TempBmp.Canvas.Brush.Style := bsClear;
    TempBmp.Canvas.Font.Assign(Font);

    if (Section.Style = hsOwnerDraw) and Assigned(OnDrawSection) then begin
      Canvas.Handle := TempBmp.Canvas.Handle;
      Self.OnDrawSection(Self, Section, Rect(0, 0, TempBmp.Width, TempBmp.Height), State = 2);
      Canvas.Handle := 0;
    end
    else begin
      if Assigned(Images) and (Section.ImageIndex >= 0) then begin
        ImgW := Images.Width;
      end
      else ImgW := 0;
      TextSize := TempBmp.Canvas.TextExtent(Section.Text);
      allw := integer(ImgW <> 0) * (ImgW + Spacing);
      if TextSize.cx > WidthOf(ItemRc) - 2 * Margin - allw then begin
        TextSize.cx := WidthOf(ItemRc) - 2 * Margin - allw;
        NewText := CutText(TempBmp.Canvas, Sections[i].Text, TextSize.cx);
      end
      else NewText := Section.Text;
      TextRC.Top := (HeightOf(R) - TextSize.cy) div 2;
      TextRC.Bottom := TextRC.Top + TextSize.cy;
      case Section.Alignment of
        taLeftJustify : begin
          if ImgW = 0
            then TextRC.Left := Margin
            else TextRC.Left := Margin + ImgW + SPacing;
          TextRC.Right := TextRC.Left + TextSize.cx
        end;
        taCenter : begin
          if ImgW = 0
            then TextRC.Left := (WidthOf(ItemRc) - TextSize.cx) div 2
            else TextRC.Left := (WidthOf(ItemRc) - TextSize.cx - ImgW - Spacing) div 2 + ImgW;
          TextRC.Right := TextRC.Left + TextSize.cx;
  //        Inc(TextRC.Left, Margin);
        end;
        taRightJustify : begin
          TextRC.Left := WidthOf(ItemRc) - TextSize.cx - Margin;
          TextRC.Right := TextRC.Left + TextSize.cx
        end;
      end;

      if (Length(Section.Text) > 0) or (ImgW > 0) then begin
        if ImgW > 0 then begin
          Images.Draw(TempBmp.Canvas,
                      TextRC.Left - ImgW - Spacing + integer(State = 2),
                      (Height - Images.Height) div 2 + integer(State = 2) - BorderWidth,
                      Section.ImageIndex, Enabled);
        end;
        if State = 2 then OffsetRect(TextRC, 1, 1);
        acWriteTextEx(TempBmp.Canvas, PacChar(NewText), True, TextRc,
             DrawTextBiDiModeFlags(DT_EXPANDTABS) or DT_SINGLELINE or DT_VCENTER,
             Si, (State <> 0), FCommonData.SkinManager);
      end;
    end;

    BitBlt(FCommonData.FCacheBMP.Canvas.Handle, ItemRc.Left + BorderWidth, BorderWidth, R.Right, R.Bottom, TempBmp.Canvas.Handle, 0, 0, SRCCOPY);
    FreeAndNil(TempBmp);
  end;
end;

procedure TsHeaderControl.PrepareCache;
var
  CI : TCacheInfo;
  b : boolean;
begin
  b := FCommonData.BGChanged;
  if (b and not FCommonData.UrgentPainting) then begin
    CI := GetParentCache(FCommonData);
    InitCacheBmp(FCommonData);
    PaintItem(FCommonData, CI, False, 0, Rect(0, 0, width, Height), Point(Left, Top), FCommonData.FCacheBMP, True);
    PaintItems;
    FCommonData.BGChanged := False;
  end;
end;

procedure TsHeaderControl.WMNCPaint(var Message: TMessage);
var
  DC, SavedDC : hdc;
  bWidth : integer;
begin
  if FCommonData.Skinned then begin
    bWidth := BorderWidth;
    DC := GetWindowDC(Handle);
    SavedDC := SaveDC(DC);
    try
      FCommonData.FUpdating := FCommonData.Updating;
      if not FCommonData.FUpdating and Showing then begin
        PrepareCache;
        ExcludeClipRect(DC, bWidth, bWidth, Width - bWidth, Height - bWidth);
        CopyWinControlCache(Self, FCommonData, Rect(0, 0, 0, 0), Rect(0, 0, Width, Height), DC, True);
        FCommonData.BGChanged := False;
      end;
    finally
      RestoreDC(DC, SavedDC);
      ReleaseDC(Handle, DC);
    end
  end
  else inherited;
end;

procedure TsHeaderControl.WMPaint(var Message: TWMPaint);
var
  DC, SavedDC : hdc;
  PS : TPaintStruct;
  bWidth : integer;
begin
  if FCommonData.Skinned then begin
    bWidth := BorderWidth;
    BeginPaint(Handle, PS);
    SavedDC := 0;
    DC := 0;
    if Message.DC = 0 then begin
      SavedDC := SaveDC(DC);
      DC := GetDC(Handle)
    end
    else DC := Message.DC;
    try
      FCommonData.FUpdating := FCommonData.Updating;
      if not FCommonData.FUpdating and Showing then begin
        PrepareCache;
        CopyWinControlCache(Self, FCommonData, Rect(bWidth, bWidth, 0, 0), Rect(0, 0, Width, Height), DC, True);
        FCommonData.BGChanged := False;
      end;
    finally
      if Message.DC = 0 then begin
        RestoreDC(DC, SavedDC);
        ReleaseDC(Handle, DC);
      end;
      EndPaint(Handle, PS);
    end
  end
  else inherited;
end;

procedure TsHeaderControl.WndProc(var Message: TMessage);
var
  p : TPoint;
  NewItem : integer;
begin
{$IFDEF LOGGED}
  AddToLog(Message);
{$ENDIF}
  if Message.Msg = SM_ALPHACMD then case Message.WParamHi of
    AC_CTRLHANDLED : begin Message.Result := 1; Exit end; // AlphaSkins supported
    AC_GETAPPLICATION : begin Message.Result := LRESULT(Application); Exit end;
    AC_REMOVESKIN : if ACUInt(Message.LParam) = ACUInt(SkinData.SkinManager) then begin
      CommonWndProc(Message, FCommonData);
      RecreateWnd;
      exit
    end;
    AC_SETNEWSKIN : if (ACUInt(Message.LParam) = ACUInt(SkinData.SkinManager)) then begin
      FCommonData.BGChanged := True;
      CommonWndProc(Message, FCommonData);
      IndexLeft := FCommonData.SkinManager.GetSkinIndex(s_ColHeaderL);
      IndexRight := FCommonData.SkinManager.GetSkinIndex(s_ColHeaderR);
      Exit
    end;
    AC_REFRESH : if (ACUInt(Message.LParam) = ACUInt(SkinData.SkinManager)) then begin
      CommonWndProc(Message, FCommonData);
      RedrawWindow(Handle, nil, 0, RDW_ERASE or RDW_FRAME or RDW_INVALIDATE or RDW_UPDATENOW);
      Exit
    end;
    AC_ENDPARENTUPDATE : if FCommonData.Updating then begin
      FCommonData.Updating := False;
      RedrawWindow(Handle, nil, 0, RDW_ERASE or RDW_FRAME or RDW_INVALIDATE or RDW_UPDATENOW);
      Exit
    end;
  end;
  if not ControlIsReady(Self) or not FCommonData.Skinned then inherited else begin
    case Message.Msg of
      HDM_DELETEITEM, HDM_INSERTITEM, HDM_SETITEM : FCommonData.BGChanged := True;
      WM_ERASEBKGND : begin
        FCommonData.FUpdating := FCommonData.Updating;
        Exit;
      end;
      WM_MOVE : if (FCommonData.SkinManager.gd[FCommonData.SkinIndex].Transparency > 0) or ((FCommonData.SkinManager.gd[FCommonData.SkinIndex].HotTransparency > 0)) then begin
        FCommonData.BGChanged := True;
      end;
      WM_PRINT : begin
        FCommonData.FUpdating := False;
        FCommonData.BGChanged := True;
        SendMessage(Handle, WM_PAINT, Message.WParam, Message.LParam);
        Exit;
      end;
      CM_MOUSELEAVE : begin
        FCommonData.BGChanged := True;
        CurItem := -1;
        PressedItem := -1;
        Repaint
      end;
      WM_LBUTTONDBLCLK, WM_LBUTTONDOWN : if not (csDesigning in ComponentState) and (Style <> hsFlat) then begin
        FCommonData.BGChanged := True;
        p.x := TCMHitTest(Message).XPos;
        p.y := TCMHitTest(Message).YPos;
        NewItem := GetItemUnderMouse(p);
        if (NewItem <> PressedItem) and (Sections[NewItem].Right - p.x > 8) and ((NewItem = 0) or (p.x - Sections[NewItem].Left > 8)) then begin
          PressedItem := NewItem;
        end;
      end;
      WM_LBUTTONUP : if not (csDesigning in ComponentState) then begin
        FCommonData.BGChanged := True;
        PressedItem := -1;
      end;
      WM_NCHITTEST : if not (csDesigning in ComponentState) and HotTrack and not (csLButtonDown in ControlState) and (Style <> hsFlat) then begin
        p.x := TCMHitTest(Message).XPos; p.y := TCMHitTest(Message).YPos + BorderWidth;
        p := Self.ScreenToClient(p);
        NewItem := GetItemUnderMouse(p);
        if (NewItem <> CurItem) then FCommonData.BGChanged := True;
        inherited;
        if (NewItem <> CurItem) then begin
          CurItem := NewItem;
          Repaint
        end;
        exit;
      end
      else if (csLButtonDown in ControlState) then FCommonData.BGChanged := True;
    end;
    CommonWndProc(Message, FCommonData);
    inherited;
    case Message.Msg of
      HDM_SETITEMA : begin
        FCommonData.Invalidate
      end;
      WM_MOVE, WM_SIZE : begin
        if csDesigning in ComponentState then Repaint;
        Perform(WM_NCPAINT, 0, 0);
      end;
    end;
  end
end;

end.
