unit acMagn;
{$I sDefs.inc}
{.$DEFINE LOGGED}

interface

uses
  Windows, Messages, Graphics, Forms, Menus, Classes,  {$IFNDEF DELPHI5}types,{$ENDIF}Controls, acThumbForm,
  ExtCtrls{$IFDEF LOGGED}, sDebugMsgs{$ENDIF};

{$IFNDEF NOTFORHELP}
const
  amMaxSize = 800;
  amMinSize = 150;
{$ENDIF}

type
  TPosChangingEvent = procedure(var X : integer; var Y : integer) of object;
  TMagnSize = amMinSize .. amMaxSize;
  TacSizingMode = (asmNone, asmFreeAspectRatio, asmFixedAspectRatio);
  TacMagnStyle = (amsRectangle, amsLens);

  TsMagnifier = class(TComponent)
{$IFNDEF NOTFORHELP}
  private
{$IFDEF D2007}
{$ENDIF}
    FScaling: integer;
    FPopupMenu: TPopupMenu;
    FOnMouseUp: TMouseEvent;
    FOnMouseDown: TMouseEvent;
    FOnPosChanging: TPosChangingEvent;
    FOnDblClick: TNotifyEvent;
    FHeight: TMagnSize;
    FWidth: TMagnSize;
    FSizingMode: TacSizingMode;
    FStyle: TacMagnStyle;
    procedure SetScaling(const Value: integer);
    procedure SetWidth(const Value: TMagnSize);
    procedure SetHeight(const Value: TMagnSize);
  public
    IsModal : boolean;
    constructor Create(AOwner : TComponent); override;
    destructor Destroy; override;
{$ENDIF}
    procedure Execute(x : integer = -1; y : integer = -1);
    procedure Hide;
    function IsVisible : Boolean;
    function GetPosition : TPoint;
    procedure Refresh;
  published
    property PopupMenu : TPopupMenu read FPopupMenu write FPopupMenu;
    property Scaling : integer read FScaling write SetScaling default 2;
    property Width : TMagnSize read FWidth write SetWidth default 280;
    property Height : TMagnSize read FHeight write SetHeight default 280;
    property SizingMode : TacSizingMode read FSizingMode write FSizingMode default asmFreeAspectRatio;
    property Style : TacMagnStyle read FStyle write FStyle default amsRectangle;

    property OnDblClick : TNotifyEvent read FOnDblClick write FOnDblClick;
    property OnMouseDown : TMouseEvent read FOnMouseDown write FOnMouseDown;
    property OnMouseUp : TMouseEvent read FOnMouseUp write FOnMouseUp;
    property OnPosChanging : TPosChangingEvent read FOnPosChanging write FOnPosChanging;
  end;

{$IFNDEF NOTFORHELP}
  TacMagnForm = class(TForm)
    PopupMenu1: TPopupMenu;
    N1x1: TMenuItem;
    N2x1: TMenuItem;
    N8x1: TMenuItem;
    N1: TMenuItem;
    Close1: TMenuItem;
    N16x1: TMenuItem;
    Timer1: TTimer;
    procedure Close1Click(Sender: TObject);
    procedure Zoom1x1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure Image1DblClick(Sender: TObject);
    procedure Image1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormResize(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure FormActivate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  protected
    IntUpdating : boolean;
    procedure WMPosChanging (var Message: TWMWindowPosChanging); message WM_WINDOWPOSCHANGING;
    function WMNCHitTest(var Message : TWMNCHitTest) : integer;
    procedure UpdateThumbPos(Full : boolean =True);
    function BordersWidth : TRect;
    procedure MakeAeroMagnifier;
  public
    Caller : TsMagnifier;
    MagnOwner : TMagnifierOwner;
    FMaskBmp : TBitmap;
    FTempBmp : TBitMap;
    AlphaBmp : TBitmap;
    Scale : Smallint;
    MagnBmp : TBitmap;
    procedure UpdateAero;
    function ContentMargins : TRect;
    procedure FormCreateInit;
    function MagnSize : TSize;
    function MClientRect : TRect;
    function MinSize : integer;
    destructor Destroy; override;
    procedure EstablishAspectRatio(Side : word; var Rect : TRect);
    procedure WndProc(var Message : TMessage); override;
    procedure SetZooming(k : integer);
    procedure ShowGlass(x, y : integer);
    procedure CreateAlphaBmp;
  end;

{$IFNDEF NOTFORHELP}
var
  Closing      : boolean = False;
  Showed       : boolean = False;
  acIsDragging : boolean = False;

{$ENDIF}

{$ENDIF}


implementation

{$R *.DFM}

uses sGraphUtils, sConst, SysUtils, sAlphaGraph, sSkinManager, sVclUtils, sMessages, acntUtils, acPNG, sSkinProvider, math, sSkinMenus;

procedure TacMagnForm.ShowGlass(x, y : integer);
var
  DC : hdc;
  FBmpSize: TSize;
  FBmpTopLeft: TPoint;
  FBlend: TBlendFunction;
  w, h, XOffs, YOffs, i, p, StepCount : integer;
  cL, cT : integer;
begin
  if IntUpdating or Closing then Exit;
  
  if (DefaultManager <> nil) then DefaultManager.SkinableMenus.HookPopupMenu(PopupMenu, (DefaultManager.Active and (DefaultManager.SkinName <> '')));

  MakeAeroMagnifier;
  with ContentMargins do begin
    cL := Left;
    cT := Top;
  end;

  w := WidthOf(MClientRect);
  h := HeightOf(MClientRect);

  XOffs := Round(X + cL + (w - w / Scale) / 2);
  YOffs := Round(Y + cT + (h - h / Scale) / 2);

  if FTempBmp <> nil then begin // If not under Aero
    FTempBmp.Width := w;
    FTempBmp.Height := h;
    DC := GetDC(0); // Copy image from screen
    StretchBlt(FTempBmp.Canvas.Handle, 0, 0, w, h, DC, XOffs, YOffs, w div Scale, h div Scale, SrcCopy);
    ReleaseDC(0, DC);
  end;

  FBmpSize.cx := MagnSize.cx;
  FBmpSize.cy := MagnSize.cy;
  FBmpTopLeft := Point(0, 0);

  with FBlend do begin
    BlendOp := AC_SRC_OVER;
    BlendFlags := 0;
    AlphaFormat := $01;
    SourceConstantAlpha := MaxByte;
  end;

  CreateAlphaBmp;

  DC := GetDC(0);
  //  Animation is disabled
  if not AeroIsEnabled and not Showed and (DefaultManager <> nil) and DefaultManager.AnimEffects.DialogShow.Active then begin
    Showed := True;
    StepCount := 20;

    FBlend.SourceConstantAlpha := 0;
    UpdateLayeredWindow(Handle, DC, nil, @FBmpSize, AlphaBmp.Canvas.Handle, @FBmpTopLeft, clNone, @FBlend, ULW_ALPHA);
    ShowWindow(Handle, SW_SHOW);

    if StepCount > 0 then begin
      p := MaxByte div StepCount;
      i := 0;
      while i <= StepCount do begin
        FBlend.SourceConstantAlpha := i * p;
        UpdateLayeredWindow(Handle, DC, nil, @FBmpSize, AlphaBmp.Canvas.Handle, @FBmpTopLeft, clNone, @FBlend, ULW_ALPHA);
        inc(i);
        if (i > StepCount) then Break;
        if StepCount > 0 then Sleep(10);
      end;
    end;
  end
  else UpdateLayeredWindow(Handle, DC, nil, @FBmpSize, AlphaBmp.Canvas.Handle, @FBmpTopLeft, clNone, @FBlend, ULW_ALPHA);
  Showed := True;
  ReleaseDC(0, DC);
end;

procedure TacMagnForm.Timer1Timer(Sender: TObject);
begin
  if (MagnOwner <> nil) then MagnOwner.MagnWnd.UpdateSource else ShowGlass(Left, Top);
end;

procedure TacMagnForm.UpdateAero;
var
  i : integer;
  DC : hdc;
  OldWidth : integer;
  function BlackWnd() : boolean;
  var
    pxl : DWord;
  begin
    DC := GetDC(0);
    pxl := GetPixel(DC, Left + MagnOwner.Width div 2, Top + Height div 2);
    Result := (pxl = clBlack) and (GetPixel(DC, Left + MagnOwner.Width div 2 + 10, Top + Height div 2) = clBlack);
    ReleaseDC(0, DC);
  end;
begin
  if MagnOwner = nil then Exit;
  IntUpdating := True;
  OldWidth := Width;
  i := 0;
  while BlackWnd and (i < 20) do begin
    Width := Width + 1;
    if not BlackWnd then Break;
    Width := OldWidth;
    inc(i);
  end;
  IntUpdating := False;
end;

procedure TacMagnForm.UpdateThumbPos(Full : boolean = True);
begin
  if MagnOwner <> nil then MagnOwner.UpdatePosition(Full);
end;

{$R magn.res}

var
  acMagnLib: HModule = 0;

procedure TacMagnForm.FormCreateInit;
var
  pg : TPNGGraphic;
  s : TResourceStream;
  CanAeroMagn : boolean;
begin
  CanAeroMagn := False;
  IntUpdating := False;
  if AeroIsEnabled then begin // FirstInit
    if acMagnLib = 0 then acMagnLib := LoadLibrary(sMagnificationDll);
    if acMagnLib <> 0 then begin
      @acMagInitialize := GetProcAddress(acMagnLib, 'MagInitialize');
      @acMagUninitialize := GetProcAddress(acMagnLib, 'MagUninitialize');
      @acMagSetWindowSource := GetProcAddress(acMagnLib, 'MagSetWindowSource');
      @acMagSetWindowTransform := GetProcAddress(acMagnLib, 'MagSetWindowTransform');
      @acMagSetWindowFilterList := GetProcAddress(acMagnLib, 'MagSetWindowFilterList');
      CanAeroMagn := Assigned(acMagInitialize);
    end;
  end;
  if not AeroIsEnabled or not CanAeroMagn then begin
    FTempBmp := CreateBmp32(WidthOf(MClientRect), HeightOf(MClientRect));
  end;
  Timer1.Enabled := True;
  Constraints.MinHeight := MinSize;
  Constraints.MinWidth := MinSize;

  pg := TPNGGraphic.Create;
  case Caller.Style of
    amsLens : s := TResourceStream.Create(hInstance, 'LENS', RT_RCDATA);
    else s := TResourceStream.Create(hInstance, 'MAGN', RT_RCDATA);
  end;
  pg.LoadFromStream(s);
  FreeAndNil(s);
  MagnBmp := TBitmap.Create;
  MagnBmp.Assign(pg);

  UpdateAlpha(MagnBmp);
  FreeAndNil(pg);
end;

procedure TacMagnForm.Close1Click(Sender: TObject);
begin
  Close;
end;

procedure TacMagnForm.SetZooming(k: integer);
begin
  Scale := k;
  if FTempBmp <> nil then ShowGlass(Left, Top) else begin
    if MagnOwner <> nil then MagnOwner.MagnWnd.MagFactor := k;
    UpdateThumbPos(True);
  end;
end;

procedure TacMagnForm.Zoom1x1Click(Sender: TObject);
begin
  Caller.Scaling := TMenuItem(Sender).Tag;
  TMenuItem(Sender).Checked := True;
end;

procedure TacMagnForm.WMPosChanging(var Message: TWMWindowPosChanging);
var
  w, h, l, r, t, b : integer;
  cL, cT, cB, cR : integer;
  function DesktopLeft : integer;
  var
    i : integer;
  begin
    Result := Monitor.Left;
    for i := 0 to Screen.MonitorCount - 1 do if Screen.Monitors[i].Left < Result then Result := Screen.Monitors[i].Left;
  end;
  function DesktopRight : integer;
  var
    i : integer;
  begin
    Result := Monitor.Left + Monitor.Width;
    for i := 0 to Screen.MonitorCount - 1 do if Screen.Monitors[i].Left + Screen.Monitors[i].Width > Result then Result := Screen.Monitors[i].Left + Screen.Monitors[i].Width;
  end;
begin
  if not IntUpdating then begin
    if not Showed or Closing or (csloading in ComponentState) or (csCreating in ControlState) or (csDestroying in ComponentState) or (csDestroying in Application.ComponentState) then Exit;

    if Assigned(TsMagnifier(Caller).OnPosChanging) and (Message.WindowPos^.cx <> 0) and (Message.WindowPos^.cy <> 0) then begin
      TsMagnifier(Caller).OnPosChanging(Message.WindowPos^.X, Message.WindowPos^.Y)
    end
    else begin
      with ContentMargins do begin
        cL := Left;
        cT := Top;
        cR := Right;
        cB := Bottom;
      end;
      w := WidthOf(MClientRect) div 2;
      h := HeightOf(MClientRect) div 2;
      l := DesktopLeft - w - cL;
      r := DesktopRight - w - cR;
      t := Screen.DesktopTop - h - cT;
      b := Screen.DesktopHeight - h - cB;

      if Message.WindowPos^.X < l then Message.WindowPos^.X := l else if Message.WindowPos^.X > r  then Message.WindowPos^.X := r;
      if Message.WindowPos^.Y < t then Message.WindowPos^.Y := t else if Message.WindowPos^.Y > b then Message.WindowPos^.Y := b;
    end;

    if (Message.WindowPos^.X = 0) and (Message.WindowPos^.Y = 0)
      then ShowGlass(Left, Top) else ShowGlass(Message.WindowPos^.X, Message.WindowPos^.Y);

    SetWindowLong(Handle, GWL_EXSTYLE, GetWindowLong(Handle, GWL_EXSTYLE) or WS_EX_TOPMOST);
  end;
end;

procedure TacMagnForm.EstablishAspectRatio(Side: word; var Rect: TRect);
var
  OldW, OldH, i, NewH, NewW : integer;
  AspRatio : real;
  cL, cR, cT, cB : integer;
begin
  with ContentMargins do begin
    cL := Left;
    cR := Right;
    cT := Top;
    cB := Bottom;
  end;
  OldH := max(Height - cL - cR, 1);
  OldW := max(Width - cT - cB, 1);
  NewH := HeightOf(Rect);
  if NewH < amMinSize then begin
    NewH := amMinSize;
    Rect.Bottom := Rect.Top + NewH;
  end
  else if NewH > amMaxSize then begin
    NewH := amMaxSize;
    Rect.Bottom := Rect.Top + NewH;
  end;
  NewW := WidthOf(Rect);
  if NewW < amMinSize then begin
    NewW := amMinSize;
    Rect.right := Rect.Left + NewW;
  end
  else if NewW > amMaxSize then begin
    NewW := amMaxSize;
    Rect.right := Rect.Left + NewW;
  end;

  AspRatio := OldH / OldW;
  with Rect do case Side of
    WMSZ_BOTTOMRIGHT, WMSZ_BOTTOM : begin
      i := Round(Left + (NewH - cT - cB) / AspRatio + cL + cR);
      if i - Left < amMinSize then begin
        i := Left + amMinSize;
        Bottom := Round(Top + (i - Left - cL - cR) * AspRatio + cT + cB);
      end
      else if i - Left > amMaxSize then begin
        i := Left + amMaxSize;
        Bottom := Round(Top + (i - Left - cL - cR) * AspRatio + cT + cB);
      end;
      Rect.Right := i;
    end;                                                      

    WMSZ_TOPLEFT, WMSZ_TOP : begin
      i := Round(Right - (NewH - cT - cB) / AspRatio - cL - cR);
      if Right - i < amMinSize then begin
        i := Right - amMinSize;
        Top := Round(Bottom - (Right - i - cL - cR) * AspRatio - cT - cB);
      end
      else if Right - i > amMaxSize then begin
        i := Right - amMaxSize;
        Top := Round(Bottom - (Right - i - cL - cR) * AspRatio - cT - cB);
      end;
      Left := i
    end;

    WMSZ_BOTTOMLEFT, WMSZ_RIGHT : begin
      i := Round(Top + (NewW - cL - cR) * AspRatio + cT + cB);
      if i - Top < amMinSize then begin
        i := Top + amMinSize;
        Right := Round(Left + (i - Top - cL - cR) / AspRatio + cL + cR);
      end
      else if i - Top > amMaxSize then begin
        i := Top + amMaxSize;
        Right := Round(Left + (i - Top - cL - cR) / AspRatio + cL + cR);
      end;
      Bottom := i;
    end;

    WMSZ_TOPRIGHT, WMSZ_LEFT : begin
      i := Round(Bottom - (WidthOf(Rect) - cL - cR) * AspRatio - cT - cB);
      if Bottom - i < amMinSize then begin
        i := Bottom - amMinSize;
        Left := Round(Right - (Bottom - i - cT - cB) / AspRatio - cL - cR);
      end
      else if Bottom - i > amMaxSize then begin
        i := Bottom - amMaxSize;
        Left := Round(Right - (Bottom - i - cT - cB) / AspRatio - cL - cR);
      end;
      Top := i;
    end;
  end
end;

procedure TacMagnForm.WndProc(var Message: TMessage);
begin
{$IFDEF LOGGED}
  AddToLog(Message);
{$ENDIF}
  case Message.Msg of
    WM_ERASEBKGND, WM_NCPAINT : Exit;
    WM_SIZING : begin
      case Caller.SizingMode of
        asmFixedAspectRatio : EstablishAspectRatio(Message.wParam, PRect(Message.lParam)^);
        asmFreeAspectRatio : inherited
      end;
      Message.Result := 0;
      exit
    end;
    WM_NCHITTEST : begin
      Message.Result := WMNCHitTest(TWMNCHitTest(Message));
      Exit;
    end;
  end;
  inherited;
  case Message.Msg of
    WM_WINDOWPOSCHANGED : begin
      SetWindowPos(Handle, HWND_TOP, 0, 0, 0, 0, SWP_NOACTIVATE or SWP_NOSIZE or SWP_NOMOVE or SWP_NOOWNERZORDER);
    end;
    WM_MOVE, WM_EXITSIZEMOVE : UpdateThumbPos(False);
    WM_SIZE, WM_ACTIVATE : if not (csDestroying in ComponentState) and not (csDestroying in Application.ComponentState) and not (csLoading in ComponentState) and Visible then begin
      if not AeroIsEnabled or (Message.Msg = WM_SIZE) then ShowGlass(Left, Top);
    end;
  end;
end;

procedure TacMagnForm.FormActivate(Sender: TObject);
begin
  UpdateThumbPos;
end;

procedure TacMagnForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if MagnOwner <> nil then FreeAndNil(MagnOwner);
  Showed := False;
  Closing := True;
  if Application.MainForm <> Self then Visible := False;
end;

procedure TacMagnForm.CreateAlphaBmp;
var
  x, y : integer;
  CSrc, CDst : TsColor_;
  Bmp : TBitmap;
  mRect : TRect;
  Mask, Dst, Src : PRGBAArray;
  wL, wR, wT, wB : integer;
  cL, cR, cT, cB : integer;
begin
  mRect := MClientRect;

  if AlphaBmp = nil then AlphaBmp := CreateBmp32(MagnSize.cx, MagnSize.cy) else begin
    AlphaBmp.Width := MagnSize.cx;
    AlphaBmp.Height := MagnSize.cy;
  end;

  Bmp := CreateBmp32(AlphaBmp.Width, AlphaBmp.Height);
  with BordersWidth do begin
    wL := Left;
    wR := Right;
    wT := Top;
    wB := Bottom;
  end;
  PaintControlByTemplate(Bmp, MagnBmp, Rect(0, 0, Bmp.Width, Bmp.Height), Rect(0, 0, MagnBmp.Width, MagnBmp.Height), Rect(wL, wT, wR, wB), Rect(MaxByte, MaxByte, MaxByte, MaxByte), Rect(1, 1, 1, 1), True);
  Bmp.Canvas.Lock;
  AlphaBmp.Canvas.Lock;
  Bmp.Modified := False;
  BitBlt(AlphaBmp.Canvas.Handle, 0, 0, Bmp.Width, Bmp.Height, Bmp.Canvas.Handle, 0, 0, SRCCOPY);
  // Copy content
  if FTempBmp <> nil then begin
    BitBlt(AlphaBmp.Canvas.Handle, mRect.Left, mRect.Top, WidthOf(mRect), HeightOf(mRect), FTempBmp.Canvas.Handle, 0, 0, SRCCOPY);
    case Caller.Style of
      amsLens : begin
        with ContentMargins do begin
          cL := Left;
          cR := Right;
          cT := Top;
          cB := Bottom;
        end;
        if FMaskBmp = nil then begin
          FMaskBmp := TBitmap.Create;
          FMaskBmp.PixelFormat := pf32bit;
        end;
        if (FMaskBmp.Width <> Bmp.Width) or (FMaskBmp.Height <> Bmp.Height) then begin // If size was changed
          FMaskBmp.Width := Bmp.Width;
          FMaskBmp.Height := Bmp.Height;
          FMaskBmp.Canvas.Brush.Color := clBlack;
          FMaskBmp.Canvas.FillRect(Rect(0, 0, FMaskBmp.Width, FMaskBmp.Height));
          FMaskBmp.Canvas.Brush.Color := clWhite;
          FMaskBmp.Canvas.RoundRect(cL, cT, FMaskBmp.Width - cR, FMaskBmp.Height - cB, 262, 262);
        end;
        for y := mRect.Top to mRect.Bottom do begin
          Dst := AlphaBmp.ScanLine[y];
          Src := Bmp.ScanLine[y];
          Mask := FMaskBmp.ScanLine[y];
          for x := mRect.Left to mRect.Right do begin
            CSrc := Src[x];
            CDst := Dst[x];
            if Mask[x].I = 0 then CDst := CSrc else begin // Exclude shadow rgn
              CDst.R := (((CSrc.R - CDst.R) * CSrc.A + CDst.R shl 8) shr 8) and MaxByte;
              CDst.G := (((CSrc.G - CDst.G) * CSrc.A + CDst.G shl 8) shr 8) and MaxByte;
              CDst.B := (((CSrc.B - CDst.B) * CSrc.A + CDst.B shl 8) shr 8) and MaxByte;
              CDst.A := MaxByte;
            end;
            Dst[x] := CDst;
          end;
        end;
      end;
      else begin
        for y := mRect.Top to mRect.Bottom do begin
          Dst := AlphaBmp.ScanLine[y];
          Src := Bmp.ScanLine[y];
          for x := mRect.Left to mRect.Right do begin
            CSrc := Src[x];
            CDst := Dst[x];
            CDst.R := (((CSrc.R - CDst.R) * CSrc.A + CDst.R shl 8) shr 8) and MaxByte;
            CDst.G := (((CSrc.G - CDst.G) * CSrc.A + CDst.G shl 8) shr 8) and MaxByte;
            CDst.B := (((CSrc.B - CDst.B) * CSrc.A + CDst.B shl 8) shr 8) and MaxByte;
            CDst.A := MaxByte;
            Dst[x] := CDst;
          end;
        end;
      end;
    end
  end
  else begin
    for y := mRect.Top to mRect.Bottom do begin // Form must be non-fully transparent for a mouse catching
      Dst := AlphaBmp.ScanLine[y];
      for x := mRect.Left to mRect.Right do begin
        CDst := Dst[x];
        if CDst.A = 0 then CDst.A := 1;
        Dst[x] := CDst;
      end;
    end;
  end;
  Bmp.Canvas.UnLock;
  AlphaBmp.Canvas.UnLock;

  FreeAndNil(Bmp);
end;

{ TsMagnifier }

constructor TsMagnifier.Create(AOwner: TComponent);
begin
  inherited;
  FScaling := 2;
  IsModal := False;
  FHeight := 280;
  FWidth := FHeight;
  FSizingMode := asmFreeAspectRatio;
  FStyle := amsRectangle;
end;

destructor TsMagnifier.Destroy;
begin
  if Assigned(acMagnForm) then FreeAndNil(acMagnForm);
  inherited;
end;

procedure ChangeAppWindow(const Handle: THandle; const SetAppWindow, RestoreVisibility: Boolean);
var
  Style: Longint;
  WasVisible, WasIconic: Boolean;
begin
  Style := GetWindowLong(Handle, GWL_EXSTYLE);
  if (SetAppWindow and (Style and WS_EX_APPWINDOW = 0)) or
     (not SetAppWindow and (Style and WS_EX_APPWINDOW = WS_EX_APPWINDOW)) then begin
    WasIconic := Windows.IsIconic(Handle);
    WasVisible := IsWindowVisible(Handle);
    if WasVisible or WasIconic then ShowWindow(Handle, SW_HIDE);
    if SetAppWindow then SetWindowLong(Handle, GWL_EXSTYLE, Style or WS_EX_APPWINDOW) else SetWindowLong(Handle, GWL_EXSTYLE, Style and not WS_EX_APPWINDOW);
    if (RestoreVisibility and WasVisible) or WasIconic then begin
      if WasIconic then ShowWindow(Handle, SW_MINIMIZE) else ShowWindow(Handle, SW_SHOW);
    end;
  end;
end;

procedure TsMagnifier.Execute(x : integer = -1; y : integer = -1);
var
  i : integer;
begin
  if acMagnForm = nil then begin
    acMagnForm := TacMagnForm.Create(nil);

    acMagnForm.Visible := False;
    TacMagnForm(acMagnForm).Caller := Self;
    acMagnForm.Constraints.MinHeight := amMinSize;
    acMagnForm.Constraints.MinWidth := amMinSize;
    with TacMagnForm(acMagnForm).BordersWidth do begin
      TacMagnForm(acMagnForm).Width := max(Width, Left + Right + 1);
      TacMagnForm(acMagnForm).Height := max(Height, Top + Bottom + 1);
    end;
    if (x <> -1) or (y <> -1) then begin
      TacMagnForm(acMagnForm).Position := poDesigned;
      acMagnForm.Left := x;
      acMagnForm.Top := y;
    end;

    TacMagnForm(acMagnForm).FormCreateInit;

    TacMagnForm(acMagnForm).Scale := FScaling;

    if FPopupMenu <> nil then TacMagnForm(acMagnForm).PopupMenu := FPopupMenu else begin
      for i := 0 to TacMagnForm(acMagnForm).PopupMenu1.Items.Count - 1 do if TacMagnForm(acMagnForm).PopupMenu1.Items[i].Tag = FScaling then begin
        TacMagnForm(acMagnForm).PopupMenu1.Items[i].Checked := True;
        Break;
      end;
    end;
    if GetWindowLong(acMagnForm.Handle, GWL_EXSTYLE) and WS_EX_LAYERED <> WS_EX_LAYERED
      then SetWindowLong(TacMagnForm(acMagnForm).Handle, GWL_EXSTYLE, GetWindowLong(acMagnForm.Handle, GWL_EXSTYLE) or WS_EX_LAYERED);
    if IsModal then TacMagnForm(acMagnForm).ShowModal else TacMagnForm(acMagnForm).Show;
  end
  else begin
    if not TacMagnForm(acMagnForm).Visible then begin
      SetFormBlendValue(TacMagnForm(acMagnForm).Handle, nil, 0);
      if IsModal then TacMagnForm(acMagnForm).ShowModal else TacMagnForm(acMagnForm).Show;
    end;
    TacMagnForm(acMagnForm).BringToFront;
  end;
end;

procedure TacMagnForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = 27 then Close;
end;

procedure TacMagnForm.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Assigned(TsMagnifier(Caller).OnMouseDown) then TsMagnifier(Caller).OnMouseDown(Caller, Button, Shift, X, Y);
  if (mbLeft = Button) then begin
    acIsDragging := True;
    ReleaseCapture;
    Perform(WM_SYSCOMMAND, SC_DRAGMOVE, 0);
  end;
end;

procedure TacMagnForm.FormResize(Sender: TObject);
begin
  if (MagnOwner <> nil) then MagnOwner.UpdatePosition();
end;

function TsMagnifier.IsVisible: Boolean;
begin
  if acMagnForm <> nil then Result := TForm(acMagnForm).Visible else Result := False;
end;

function TsMagnifier.GetPosition: TPoint;
begin
  if acMagnForm <> nil then begin
    Result.X := TForm(acMagnForm).Left;
    Result.Y := TForm(acMagnForm).Top ;
  end
  else begin
    Result.X := -1;
    Result.Y := -1;
  end;
end;

procedure TsMagnifier.Hide;
begin
  if acMagnForm <> nil then TForm(acMagnForm).Close;
end;

procedure TsMagnifier.SetScaling(const Value: integer);
begin
  if FScaling = Value then Exit;
  if Value < 2 then FScaling := 2 else if Value > 16 then FScaling := 16 else FScaling := Value;
  if acMagnForm <> nil then TacMagnForm(acMagnForm).SetZooming(FScaling);
end;

procedure TacMagnForm.FormShow(Sender: TObject);
begin
  Closing := False;
end;

procedure TacMagnForm.Image1DblClick(Sender: TObject);
begin
  if Assigned(TsMagnifier(Caller).OnDblClick) then TsMagnifier(Caller).OnDblClick(Caller);
end;

procedure TacMagnForm.Image1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
{$IFDEF DELPHI7UP}
  if not Mouse.IsDragging and acIsDragging then
{$ENDIF}
  begin
    if Assigned(TsMagnifier(Caller).OnMouseUp) then TsMagnifier(Caller).OnMouseUp(TObject(Caller), mbLeft, Shift, X, Y);
    acIsDragging := False;
  end
end;

destructor TacMagnForm.Destroy;
begin
  if Assigned(MagnOwner) then FreeAndNil(MagnOwner);
  if Assigned(MagnBmp) then FreeAndNil(MagnBmp);

  if Assigned(FTempBmp) then FreeAndNil(FTempBmp);

  if Assigned(FMaskBmp) then FreeAndNil(FMaskBmp);
  if Assigned(AlphaBmp) then FreeAndNil(AlphaBmp);
  inherited;
end;

procedure TsMagnifier.Refresh;
begin
  if Assigned(acMagnForm) then SendMessage(acMagnForm.Handle, SM_ALPHACMD, MakeWParam(0, AC_REFRESH), 0);
end;

function TacMagnForm.WMNCHitTest(var Message: TWMNCHitTest) : integer;
const
  bWidth = 8;
  HitArrayLT : array[boolean, boolean] of Cardinal = ((HTCLIENT, HTTOP), (HTLEFT, HTTOPLEFT));
  HitArrayBR : array[boolean, boolean] of Cardinal = ((HTCLIENT, HTBOTTOM), (HTRIGHT, HTBOTTOMRIGHT));
var
  p : TPoint;
  mRect : TRect;
  R1, R2 : integer;
begin
  p := Point(Message.Pos.x, Message.Pos.y);
  p := ScreenToClient(p);
  mRect := MClientRect;
  InflateRect(mRect, 4, 4);
  if PTInRect(mRect, p) then begin
    if Caller.SizingMode <> asmNone then begin
      R1 := HitArrayLT[PtInRect(Rect(mRect.Left, mRect.Top, mRect.Left + bWidth, mRect.Bottom), p), PtInRect(Rect(mRect.Left, mRect.Top, mRect.Right, mRect.Top + bWidth), p)];
      R2 := HitArrayBR[PtInRect(Rect(mRect.Right - bWidth, mRect.Top, mRect.Right, mRect.Bottom), p), PtInRect(Rect(mRect.Left, mRect.Bottom - bWidth, mRect.Right, mRect.Bottom), p)];
      if R1 = HTCLIENT then Result := R2 else begin
        if (R1 = HTTOP) and (R2 = HTRIGHT)
          then Result := HTTOPRIGHT
          else if (R1 = HTLEFT) and (R2 = HTBOTTOM)
            then Result := HTBOTTOMLEFT
            else Result := R1;
      end;
    end
    else Result := HTCLIENT;
  end
  else Result := HTTRANSPARENT;
end;

function TacMagnForm.MClientRect: TRect;
var
  cL, cR, cT, cB : integer;
begin
  if acMagnForm <> nil then begin
    with ContentMargins do begin
      cL := Left;
      cR := Right;
      cT := Top;
      cB := Bottom;
    end;
    Result := Rect(cL, cT, MagnSize.cx - cR, MagnSize.cy - cB)
  end
  else Result := Rect(0, 0, 0, 0);
end;

function TacMagnForm.MagnSize: TSize;
begin
  if acMagnForm <> nil then begin
    Result.cx := max(MinSize, acMagnForm.Width);
    Result.cy := max(MinSize, acMagnForm.Height);
    Result.cx := min(amMaxSize, Result.cx);
    Result.cy := min(amMaxSize, Result.cy);
  end;
end;

procedure TacMagnForm.MakeAeroMagnifier;
begin
  if acMagnLib = 0 then Exit;
  if MagnOwner = nil then begin
    MagnOwner := TMagnifierOwner.Create(Self);
//    MagnOwner.Constraints.MinWidth := MinSize;
//    MagnOwner.Constraints.MinHeight := MinSize;
    UpdateAero;
  end
  else MagnOwner.MagnWnd.Refresh;
end;

function TacMagnForm.BordersWidth: TRect;
begin
  case Caller.Style of
    amsLens : Result := Rect(139, 139, 139, 139)
    else Result := Rect(50, 50, 50, 50);
  end;
end;

function TacMagnForm.ContentMargins: TRect;
begin
  case Caller.Style of
    amsLens : Result := Rect(8, 8, 9, 10)
    else Result := Rect(24, 21, 26, 29);
  end;
end;

function TacMagnForm.MinSize: integer;
begin
  case Caller.Style of
    amsLens : Result := 280
    else Result := 150;
  end;
end;

procedure TsMagnifier.SetWidth(const Value: TMagnSize);
begin
  FWidth := min(max(Value, amMinSize), amMaxSize);
end;

procedure TsMagnifier.SetHeight(const Value: TMagnSize);
begin
  FHeight := min(max(Value, amMinSize), amMaxSize);
end;

end.
