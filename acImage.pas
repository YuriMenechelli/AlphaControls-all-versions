unit acImage;
{$I sDefs.inc}
{.$DEFINE LOGGED}

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Imglist, {$IFNDEF DELPHI5}Types, {$ENDIF}
  sConst, sDefaults, comctrls, menus, ExtCtrls, acAlphaImageList, sCommonData;

type
  // 2 Src : Picture property and ImageList
  // Create a CacheBmp after each changing
  // Copy CacheBmp to Canvas in Paint procedure

  TsCustomImage = class(TImage)
  private
    FGrayed: boolean;
    FReflected: boolean;
    FBlend: integer;
    FImageChangeLink: TChangeLink;
    FImageIndex: integer;
    FImages: TCustomImageList;
    FCommonData: TsCtrlSkinData;
    FUseFullSize: boolean;
    procedure SetBlend(const Value: integer);
    procedure SetGrayed(const Value: boolean);
    procedure SetImageIndex(const Value: integer);
    procedure SetImages(const Value: TCustomImageList);
    procedure SetReflected(const Value: boolean);
    procedure ImageListChange(Sender: TObject);
    procedure SetUseFullSize(const Value: boolean);
  protected
    ImageChanged : boolean;
    FImage : TBitmap;
    function CanAutoSize(var NewWidth, NewHeight: Integer): Boolean; override;
    function OwnDrawing : boolean;
    function PrepareCache(DC: HDC) : boolean; virtual;
  public
    procedure AfterConstruction; override;
    constructor Create(AOwner:TComponent); override;
    procedure UpdateImage;

    function Empty : boolean;
    destructor Destroy; override;
    procedure acWM_PAINT(var Message: TWMPaint); message WM_PAINT;
    procedure WndProc (var Message: TMessage); override;

    property Blend : integer read FBlend write SetBlend default 0;
    property UseFullSize : boolean read FUseFullSize write SetUseFullSize default False;  
    property ImageIndex : integer read FImageIndex write SetImageIndex default -1;
    property Images: TCustomImageList read FImages write SetImages;
    property Grayed : boolean read FGrayed write SetGrayed default False;
    property Reflected : boolean read FReflected write SetReflected default False;
    property SkinData : TsCtrlSkinData read FCommonData write FCommonData;
  end;

  TsImage = class(TsCustomImage)
  published
    property Blend;
    property ImageIndex;
    property Images;
    property Grayed;
    property Picture;
    property Reflected;
    property SkinData;
    property UseFullSize;  
  end;

implementation

uses sGraphUtils, sVCLUtils, sMessages, acntUtils, sMAskData, sAlphaGraph, sStyleSimply, sSkinProps, acGlow, math, sPanel, acTinyJpg,
  sBitBtn, sThirdParty{$IFDEF LOGGED}, sDebugMsgs{$ENDIF}, ActnList, sSkinManager, sBorders{$IFDEF DELPHI7UP}, Themes{$ENDIF};


{ TsCustomImage }

procedure TsCustomImage.AfterConstruction;
begin
  inherited;
end;

constructor TsCustomImage.Create(AOwner: TComponent);
begin
  inherited;
  FCommonData := TsCtrlSkinData.Create(Self, True);
  FImage := TBitmap.Create;
  FCommonData.COC := COC_TsImage;
  FImageChangeLink := TChangeLink.Create;
  FImageChangeLink.OnChange := ImageListChange;
  ImageChanged := True;
  FImageIndex := -1;
end;

destructor TsCustomImage.Destroy;
begin
  if Assigned(FCommonData) then FreeAndNil(FCommonData);
  FreeAndNil(FImageChangeLink);
  FreeAndNil(FImage);
  inherited;
end;

{
function TsCustomImage.UpdateBitmap: boolean;
var
  Size: TSize;
  TmpBmp : TBitmap;
  Own : boolean;
  function GetActualSize(CalcShadow : boolean = True) : TSize;
  begin
    if (ImageIndex >= 0) and (Images <> nil) then begin
      Result.cx := Images.Width;
      Result.cy := Images.Height;
    end
    else begin
      Result.cx := Picture.Width;
      Result.cy := Picture.Height;
    end;
    if CalcShadow and Reflected then inc(Result.cy, Result.cy div 3);
  end;
begin
  FCommonData.BGChanged := True;
  if (csLoading in ComponentState) or (csCreating in ControlState) then Exit;
  Size := GetActualSize;
  Own := OwnDrawing;
  // If additional effects required
  if Own then TmpBmp := CreateBmp32(Size.cx, GetActualSize(False).cy) else TmpBmp := FImage;

  // If should internal image be updated
  if (ImageIndex >= 0) and (Images <> nil) then begin
    // Get bitmap from imagelist
    TmpBmp.Width := Images.Width;
    TmpBmp.Height := Images.Height;
    if Images is TsAlphaImageList
      then TsAlphaImageList(Images).GetBitmap32(ImageIndex, TmpBmp)
      else Images.GetBitmap(ImageIndex, TmpBmp);
  end
  else if not Picture.Bitmap.Empty then begin
    TmpBmp.Assign(Picture.Bitmap);
  end
  else if not Picture.Graphic.Empty then begin
    TmpBmp.Assign(Picture.Graphic);
  end;

  // If Additional options are available
  if OwnDrawing then begin
    FImage.Width := Size.cx;
    FImage.Height := Size.cy;
    // Clear bitmap
    FillRect32(FImage, Rect(0, 0, Size.cx, Size.cy), 0, 0);
    CopyBmp32(Rect(0, 0, Size.cx, Size.cy), Rect(0, 0, TmpBmp.Width, TmpBmp.Height), FImage, TmpBmp, EmptyCI, False, iffi(Grayed, 0, clNone), Blend, Reflected);

    TmpBmp.Free;
  end;

  ImageChanged := False;
end;
}
procedure TsCustomImage.SetBlend(const Value: integer);
begin
  if FBlend <> Value then begin
    FBlend := Value;
    Skindata.Invalidate;
  end;
end;

procedure TsCustomImage.SetGrayed(const Value: boolean);
begin
  if FGrayed <> Value then begin
    FGrayed := Value;
    Skindata.Invalidate;
  end;
end;

procedure TsCustomImage.SetImageIndex(const Value: integer);
begin
  if FImageIndex <> Value then begin
    FImageIndex := Value;
    Skindata.Invalidate;
  end;
end;

procedure TsCustomImage.SetImages(const Value: TCustomImageList);
begin
  if FImages <> Value then begin
    if FImages <> nil then Images.UnRegisterChanges(FImageChangeLink);
    FImages := Value;
    if Images <> nil then begin
      Images.RegisterChanges(FImageChangeLink);
      Images.FreeNotification(Self);
    end;
    UpdateImage;
  end;
end;

procedure TsCustomImage.SetReflected(const Value: boolean);
begin
  if FReflected <> Value then begin
    FReflected := Value;
    Skindata.Invalidate;
  end;
end;

procedure TsCustomImage.ImageListChange(Sender: TObject);
begin
  Skindata.Invalidate;
end;

function TsCustomImage.OwnDrawing: boolean;
begin
  Result := Reflected or Grayed or (Blend > 0);// or (Images <> nil) and (ImageIndex >= 0) and (Images is TsAlphaImageList);
end;

function TsCustomImage.PrepareCache(DC: HDC): boolean;
var
  CI : TCacheInfo;
  BGInfo : TacBGInfo;
  R : TRect;
  procedure DrawImage;
  var
    StretchSize, Size: TSize;
    TmpBmp, StretchSrc : TBitmap;
    l, t : integer;
    function GetSrcSize(CalcStretch : boolean = True) : TSize;
    var
      SrcHeight : integer;
      xyaspect : real;
    begin
      if (ImageIndex >= 0) and (Images <> nil) then begin
        Result.cx := Images.Width;
        Result.cy := Images.Height;
      end
      else begin
        Result.cx := Picture.Width;
        Result.cy := Picture.Height;
      end;
      if CalcStretch then begin
        SrcHeight := Height;
        if Reflected then SrcHeight := SrcHeight * 2 div 3;
{$IFNDEF DELPHI5}
	if Proportional then begin
          xyaspect := Result.cx / Result.cy;
          if Result.cx > Result.cy then begin
            Result.cx := Width;
            Result.cy := Trunc(Width / xyaspect);
            if Result.cy > SrcHeight then begin
              Result.cy := SrcHeight;
              Result.cx := Trunc(Result.cy * xyaspect);
            end;
          end
          else begin
            Result.cy := SrcHeight;
            Result.cx := Trunc(Result.cy * xyaspect);
            if Result.cx > Width then begin
              Result.cx := Width;
              Result.cy := Trunc(Result.cx / xyaspect);
            end;
          end;
        end
        else
{$ENDIF}        
        begin
          Result.cx := Width;
          Result.cy := SrcHeight;
        end;
      end;
    end;
  begin
    Size := GetSrcSize(False);
    StretchSize := GetSrcSize(Stretch);
    TmpBmp := CreateBmp32(Size.cx, Size.cy);
    if (ImageIndex >= 0) and (Images <> nil) then begin
      // Get bitmap from imagelist
      TmpBmp.Width := Images.Width;
      TmpBmp.Height := Images.Height;
      if Images is TsAlphaImageList
        then TsAlphaImageList(Images).GetBitmap32(ImageIndex, TmpBmp)
        else if Images is TsVirtualImageList
          then TsVirtualImageList(Images).GetBitmap32(ImageIndex, TmpBmp)
          else Images.GetBitmap(ImageIndex, TmpBmp);
      if Stretch then begin
        StretchSrc := TmpBmp;
        TmpBmp := CreateBmp32(StretchSize.cx, StretchSize.cy);
        sGraphUtils.Stretch(StretchSrc, TmpBmp, StretchSize.cx, StretchSize.cy, ftMitchell);
        StretchSrc.Free;
      end;
    end
    else if not (Picture.Graphic is TBitmap) then begin
      TmpBmp.Width := StretchSize.cx;
      TmpBmp.Height := StretchSize.cy;

      R := Rect(0, 0, TmpBmp.Width, TmpBmp.Height);
{      R.Left := 0;
      R.Top := 0;
}
      R.Right := min(Width, R.Left + StretchSize.cx);
      R.Bottom := min(Height, R.Top + StretchSize.cy);
      TmpBmp.Canvas.StretchDraw(R, Picture.Graphic);
      FillAlphaRect(TmpBmp, R, MaxByte);
    end
    else if not Picture.Bitmap.Empty then begin
      TmpBmp.Assign(Picture.Bitmap);
      if Stretch then begin
        StretchSrc := TmpBmp;
        TmpBmp := CreateBmp32(StretchSize.cx, StretchSize.cy);
        sGraphUtils.Stretch(StretchSrc, TmpBmp, StretchSize.cx, StretchSize.cy, ftMitchell);
        StretchSrc.Free;
      end;
    end;
    if Stretch {$IFDEF DELPHI6UP}and (not Proportional){$ENDIF} or not Center then begin
      l := 0;
      t := 0;
    end
    else begin
      l := (Width - TmpBmp.Width) div 2;
      t := (Height - TmpBmp.Height - integer(FUseFullSize) * (TmpBmp.Height div 2)) div 2;
    end;
    CopyBmp32(Rect(l, t, l + TmpBmp.Width, t + TmpBmp.Height), Rect(0, 0, TmpBmp.Width, TmpBmp.Height), FCommonData.FCacheBmp, TmpBmp, EmptyCI, False, iffi(Grayed, {GetBGColor(SkinData, 0)}$FFFFFF, clNone), Blend, Reflected);
    TmpBmp.Free;
  end;
begin
  Result := True;
  GetBGInfo(@BGInfo, Parent);
  if BGInfo.BgType = btNotReady then begin
    FCommonData.FUpdating := True;
    Result := False;
    Exit;
  end;
  CI := BGInfoToCI(@BGInfo);

  InitCacheBmp(SkinData);
  if CI.Ready and CI.Bmp.Empty then Exit;

  BitBlt(FCommonData.FCacheBmp.Canvas.Handle, 0, 0, Width, Height, DC, 0, 0, SRCCOPY);

  PaintItem(FCommonData, CI, True, 0, Rect(0, 0, Width, Height), Point(Left, Top), FCommonData.FCacheBMP, True, 0, 0);
  DrawImage;

  FCommonData.BGChanged := False;
end;

procedure TsCustomImage.WndProc(var Message: TMessage);
begin
{$IFDEF LOGGED}
  AddToLog(Message);
{$ENDIF}
  if FCommonData <> nil then case Message.Msg of
    WM_ERASEBKGND : Exit;
    WM_WINDOWPOSCHANGED, WM_SIZE : begin
      if Visible then FCommonData.BGChanged := True;
    end;
    CM_VISIBLECHANGED : begin
      FCommonData.BGChanged := True;
      SkinData.FMouseAbove := False
    end;
  end;
  inherited;
end;

procedure TsCustomImage.acWM_PAINT(var Message: TWMPaint);
var
  SavedDC : hdc;
begin
  if not InUpdating(FCommonData) and not Empty then begin
    SavedDC := SaveDC(Message.DC);
    try
      if FCommonData.BGChanged or ImageChanged then PrepareCache(Message.DC);
      BitBlt(Message.DC, 0, 0, Width, Height, FCommonData.FCacheBmp.Canvas.Handle, 0, 0, SRCCOPY);
    finally
      RestoreDC(Message.DC, SavedDC);
    end;
  end
  else inherited;
end;

function TsCustomImage.Empty: boolean;
begin
  if (FImages <> nil) and ((FImageIndex >= 0) and (FImageIndex < FImages.Count)) then begin
    Result := False;
  end
  else
  if Picture.Graphic <> nil
    then Result := Picture.Graphic.Empty
    else if Picture.Bitmap <> nil
      then Result := Picture.Bitmap.Empty
      else Result := True;
end;

procedure TsCustomImage.UpdateImage;
begin
  if not (csLoading in ComponentState) and not (csDestroying in ComponentState) then Repaint;
end;

procedure TsCustomImage.SetUseFullSize(const Value: boolean);
begin
  if FUseFullSize <> Value then begin
    FUseFullSize := Value;
    Skindata.Invalidate;
  end;
end;

function TsCustomImage.CanAutoSize(var NewWidth, NewHeight: Integer): Boolean;
var
  w, h : integer;
begin
  Result := True;
  if not (csDesigning in ComponentState) or not Empty then begin
    if (Images <> nil) and Between(ImageIndex, 0, Images.Count) then begin
      w := Images.Width;
      h := Images.Height;
    end
    else begin
      w := Picture.Width;
      h := Picture.Height;
    end;
    if Align in [alNone, alLeft, alRight] then NewWidth := w;
    if Align in [alNone, alTop, alBottom] then begin
      NewHeight := h;
      if FUseFullSize and FReflected then inc(NewHeight, NewHeight div 2)
    end;
  end
  else inherited CanAutoSize(NewWidth, NewHeight);
end;

end.
