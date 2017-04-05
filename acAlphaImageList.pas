unit acAlphaImageList;
{$I sDefs.inc}

interface

uses
  Windows, Classes, SysUtils, Controls, Graphics, CommCtrl, ImgList, ComCtrls, sConst, acPNG, {$IFDEF DELPHI_XE3}UITypes, {$ENDIF}acntUtils;

type
  TsImageFormat = (ifPNG, ifICO, ifBMP32);
{$IFNDEF NOTFORHELP}
  TsAlphaImageList = class;
  TsImgListItems = class;

  TsImgListItem = class(TCollectionItem)
  private
    FImageFormat: TsImageFormat;
    FPixelFormat: TPixelFormat;
  protected
    FOwner : TsImgListItems;
    OrigWidth : integer;
    OrigHeight : integer;
    procedure DefineProperties(Filer: TFiler); override;
    procedure ReadData(Reader: TStream);
    procedure WriteData(Writer: TStream);
  public
    ImgData : TMemoryStream;
    CacheBmp : TBitmap;
    procedure Assign(Source: TPersistent); override;
    procedure AssignTo(Dest: TPersistent); override;
    destructor Destroy; override;
    constructor Create(Collection: TCollection); override;
  published
    property ImageFormat : TsImageFormat read FImageFormat write FImageFormat;
    property PixelFormat : TPixelFormat read FPixelFormat write FPixelFormat default pf32bit;
  end;

  TsImgListItems = class(TCollection)
  protected
    FOwner: TsAlphaImageList;
    function GetItem(Index: Integer): TsImgListItem;
    procedure SetItem(Index: Integer; Value: TsImgListItem);
    function GetOwner: TPersistent; override;
  public
    constructor Create(AOwner : TsAlphaImageList);
    destructor Destroy; override;
    property Items[Index: Integer]: TsImgListItem read GetItem write SetItem; default;
  end;
{$ENDIF}

  TsAlphaImageList = class(TImageList)
{$IFNDEF NOTFORHELP}
  private
    FItems: TsImgListItems;
    StdListIsGenerated : boolean;
    AcChanging : boolean;
    FBkColor : TColor;
    FUseCache: boolean;
    procedure SetItems(const Value: TsImgListItems);
    function GetBkColor: TColor;
    procedure SetBkColor(const Value: TColor);
    procedure SetUseCache(const Value: boolean);
  protected
    procedure CreateImgList;
    procedure Change; override;
    procedure DoDraw(Index: Integer; Canvas: TCanvas; X, Y: Integer; Style: Cardinal; Enabled: Boolean = True); override;
    procedure KillImgList;
    function IsDuplicated : boolean;
    function TryLoadFromFile(const FileName : acString) : boolean;
{$IFDEF DELPHI7UP}
    procedure ReadData(Stream: TStream); override;
    procedure WriteData(Stream: TStream); override;
{$ENDIF}
    procedure ItemsClear;
  public
    DoubleData : boolean;
    procedure AcBeginUpdate;
    procedure AcEndUpdate(DoChange : boolean = True);
    function Add(Image, Mask: TBitmap): Integer;
    procedure AfterConstruction; override;
    procedure Assign(Source: TPersistent); override;
    procedure AssignTo(Dest: TPersistent); override;
    procedure CopyImages(const ImgList : TsAlphaImageList);
    constructor Create(AOwner : TComponent); override;
    destructor Destroy; override;
    procedure GenerateStdList;
    function GetBitmap32(Index: Integer; Image: TBitmap): Boolean;
    function CreateBitmap32(Index: Integer; aWidth, aHeight : integer): TBitmap;
    procedure Loaded; override;
    procedure LoadFromFile(const FileName : acString);
    procedure MoveItem(CurIndex, NewIndex : integer);
    procedure SetNewDimensions(Value: HImageList);
  published
    property BkColor: TColor read GetBkColor write SetBkColor default clNone;
    property Items : TsImgListItems read FItems write SetItems;
    property UseCache : boolean read FUseCache write SetUseCache default True;
{$ENDIF}
  end;

  TsVirtualImageList = class(TCustomImageList)
{$IFNDEF NOTFORHELP}
  private
    CachedImages : array of TBitmap;
    FImageChangeLink: TChangeLink;
    StdListIsGenerated : boolean;
    AcChanging : boolean;
    FHeight: integer;
    FWidth: integer;
    FAlphaImageList: TsAlphaImageList;
    FUseCache: boolean;
    procedure SetHeight(const Value: integer);
    procedure SetWidth(const Value: integer);
    procedure SetAlphaImageList(const Value: TsAlphaImageList);
    procedure SetUseCache(const Value: boolean);
  protected
    procedure CreateImgList;
    procedure Change; override;
    procedure DoDraw(Index: Integer; Canvas: TCanvas; X, Y: Integer; Style: Cardinal; Enabled: Boolean = True); override;
    procedure KillImgList;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure ImageListChange(Sender: TObject);
  public
    procedure AcBeginUpdate;
    procedure AcEndUpdate(DoChange : boolean = True);
    procedure AfterConstruction; override;
    constructor Create(AOwner : TComponent); override;
    destructor Destroy; override;
    function Count : integer; 
    procedure GenerateStdList;
    function GetBitmap32(Index: Integer; Image: TBitmap): Boolean;
    procedure ClearItems;
    procedure Loaded; override;
    procedure UpdateList(IgnoreGenerated : boolean = True);
  published
{$ENDIF}
    property AlphaImageList : TsAlphaImageList read FAlphaImageList write SetAlphaImageList;
    property Height : integer read FHeight write SetHeight default 16;
    property UseCache : boolean read FUseCache write SetUseCache default True;
    property Width : integer read FWidth write SetWidth default 16;
  end;

{$IFNDEF NOTFORHELP}
function GetImageFormat(const FileName : acString; var ImageFormat : TsImageFormat) : boolean;
function DrawAlphaImgList(const ImgList : TCustomImageList; const DestBmp : TBitmap; const Left : integer; const Top : integer;
  const ImageIndex : integer; const Blend : integer; const GrayedColor : TColor; State : integer; const NumGlyphs : integer; const Reflected : boolean) : TSize;
procedure DrawAlphaImgListDC(const ImgList : TCustomImageList; const DC : hdc; const Left : integer; const Top : integer;
  const ImageIndex : integer; const Blend : integer; const GrayedColor : TColor; const State : integer; const NumGlyphs : integer; const Reflected : boolean);
function HaveMagic(const FileName : string; const Magic: Pointer; const Size : integer): Boolean;
{$ENDIF}
function AddImageFromRes(aInstance: LongWord; ImageList : TsAlphaimageList; const ResName: String; ImageFormat : TsImageFormat): Boolean; // Png must be compiled in resource as RcData

implementation

uses math, ShellAPI, sGraphUtils, Dialogs, Forms, sAlphaGraph, sThirdParty;

{ TsAlphaImageList }

function GetBpp : integer;
var
  ScreenDC : hdc;
begin
  ScreenDC := GetDC(0);
  try
    Result := GetDeviceCaps(ScreenDC, BITSPIXEL);
  finally
    ReleaseDC(0, ScreenDC)
  end;
end;

function GetImageFormat(const FileName : acString; var ImageFormat : TsImageFormat) : boolean;
const
  IcoMagic: array[0..1] of Byte = (0, 0);
  BmpMagic: array[0..1] of Char = ('B', 'M');
var
  s : string;
begin
  Result := False;
  // Check format
  if HaveMagic(FileName, @PNGMagic, 8) then begin // Png
    ImageFormat := ifPNG;
    Result := True;
  end
  else if HaveMagic(FileName, @IcoMagic, 2) then begin // Ico
    s := LowerCase(ExtractFileExt(FileName));
    System.Delete(s, 1, 1);
    if s = acIcoExt then begin
      ImageFormat := ifICO;
      Result := True;
    end;
  end
  else if HaveMagic(FileName, @BmpMagic, 2) then begin // Bmp32
    ImageFormat := ifBMP32;
    Result := True;
  end;
end;

function DrawAlphaImgList(const ImgList : TCustomImageList; const DestBmp : TBitmap; const Left : integer; const Top : integer;
  const ImageIndex : integer; const Blend : integer; const GrayedColor : TColor; State : integer; const NumGlyphs : integer; const Reflected : boolean) : TSize;
var
  Bmp : TBitmap;
  w, Count : integer;
  R1, R2 : TRect;
begin
  if (DestBmp.Width = 0) or not ImgList.HandleAllocated or (ImageIndex < 0) then Exit;
  Count := NumGlyphs;
  w := ImgList.Width div Count;
  if State >= Count then State := Count - 1;
  R1 := Rect(Left, Top, Left + w, Top + ImgList.Height);
  R2 := Rect(0, 0, w, ImgList.Height);
  Result.cx := w;
  Result.cy := ImgList.Height;
  OffsetRect(R2, w * State, 0);

  Bmp := nil;
  if (ImgList is TsAlphaImageList) then begin
    Bmp := TsAlphaImageList(ImgList).CreateBitmap32(ImageIndex, ImgList.Width, ImgList.Height);
    if Bmp <> nil then CopyBmp32(R1, R2, DestBmp, Bmp, EmptyCI, False, GrayedColor, Blend, Reflected);
  end
  else if (ImgList is TsVirtualImageList) then begin
    if TsVirtualImageList(ImgList).UseCache then begin
      if (Length(TsVirtualImageList(ImgList).CachedImages) > ImageIndex) then begin
        if TsVirtualImageList(ImgList).CachedImages[ImageIndex] = nil
//          then TsVirtualImageList(ImgList).AlphaImageList.GetBitmap32(ImageIndex, TsVirtualImageList(ImgList).CachedImages[ImageIndex]);
          then TsVirtualImageList(ImgList).CachedImages[ImageIndex] := TsVirtualImageList(ImgList).AlphaImageList.CreateBitmap32(ImageIndex, ImgList.Width, ImgList.Height);
        CopyBmp32(R1, R2, DestBmp, TsVirtualImageList(ImgList).CachedImages[ImageIndex], EmptyCI, False, GrayedColor, Blend, Reflected)
      end;
    end
    else begin
      Bmp := CreateBmp32(ImgList.Width, ImgList.Height);
      TsVirtualImageList(ImgList).GetBitmap32(ImageIndex, Bmp);
      if Bmp <> nil then CopyBmp32(R1, R2, DestBmp, Bmp, EmptyCI, False, GrayedColor, Blend, Reflected);
    end;
  end
  else begin
    Bmp := CreateBmp32(ImgList.Width, ImgList.Height);
    BitBlt(Bmp.Canvas.Handle, R2.Left, R2.Top, WidthOf(R2), HeightOf(R2), DestBmp.Canvas.Handle, R1.Left, R1.Top, SRCCOPY);
    ImgList.Draw(Bmp.Canvas, 0, 0, ImageIndex, True);
    BitBlt(DestBmp.Canvas.Handle, R1.Left, R1.Top, WidthOf(R2), HeightOf(R2), Bmp.Canvas.Handle, R2.Left, R2.Top, SRCCOPY);
  end;
  if Bmp <> nil then FreeAndNil(Bmp);
end;

procedure DrawAlphaImgListDC(const ImgList : TCustomImageList; const DC : hdc; const Left : integer; const Top : integer;
  const ImageIndex : integer; const Blend : integer; const GrayedColor : TColor; const State : integer; const NumGlyphs : integer; const Reflected : boolean);
var
  Bmp : TBitmap;
  Size : TSize;
begin
  Bmp := CreateBmp32(ImgList.Width, ImgList.Height + Integer(Reflected) * ImgList.Height div 2);
  BitBlt(Bmp.Canvas.Handle, 0, 0, Bmp.Width, Bmp.Height, DC, Left, Top, SRCCOPY);
  Size := DrawAlphaImgList(ImgList, Bmp, 0, 0, ImageIndex, Blend, GrayedColor, State, NumGlyphs, Reflected);
  BitBlt(DC, Left, Top, Bmp.Width, Bmp.Height, Bmp.Canvas.Handle, 0, 0, SRCCOPY);
  FreeAndNil(Bmp);
end;

function HaveMagic(const FileName : string; const Magic: Pointer; const Size : integer): Boolean;
var
  MagicBuf: array[0..7] of Byte;
  Stream: TFileStream;
  len: integer;
begin
  FillChar(MagicBuf, 8, #0);
  Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    len := min(Size, SizeOf(MagicBuf));
    Result := (Stream.Size - Stream.Position) > len;
    if Result then begin
      Stream.ReadBuffer(MagicBuf, len);
      Result := CompareMem(@MagicBuf, Magic, len);
    end;
  finally
    FreeAndNil(Stream);
  end;
end;

function AddImageFromRes(aInstance: LongWord; ImageList : TsAlphaimageList; const ResName: String; ImageFormat : TsImageFormat): Boolean;
var
  hIc : HICON;
  Png : TPNGGraphic;
  rs : TResourceStream;
  Ico : hIcon;
begin
  Result := False;
  if ImageFormat = ifICO then begin
    hIc := LoadImage(aInstance, PChar(ResName), IMAGE_ICON, ImageList.Width, ImageList.Height, 0);
    if hIc = 0 then Exit;
    try
      if ImageList_AddIcon(ImageList.Handle, hIc) <> -1 then begin
        Result := True;
      end;
    finally
      DestroyIcon(hIc);
    end;
  end
  else begin
    Png := TPNGGraphic.Create;
    rs := TResourceStream.Create(aInstance, ResName, RT_RCDATA);
    rs.Seek(0, 0);
    with TsImgListItem.Create(ImageList.Items) do begin // Add to Items
      ImageFormat := ifPNG;
      ImgData.LoadFromStream(rs);
    end;
    rs.Seek(0, 0);
    Png.LoadFromStream(rs);       
    FreeAndNil(rs);
    Ico := MakeIcon32(Png);
    Result := ImageList_AddIcon(ImageList.Handle, Ico) <> -1; 
    DestroyIcon(Ico);
    FreeAndNil(Png);
  end;
end;

procedure TsAlphaImageList.AfterConstruction;
begin
  inherited;
  if not (csLoading in ComponentState) then begin
    if not HandleAllocated then CreateImgList;
    if not StdListIsGenerated then GenerateStdList;
  end;
end;

function GetColor(Value: DWORD): TColor;
begin
  case Value of
    CLR_NONE: Result := clNone;
    CLR_DEFAULT: Result := clDefault;
  else
    Result := TColor(Value);
  end;
end;

procedure TsAlphaImageList.Assign(Source: TPersistent);
var
  ImageList: TsAlphaImageList;
begin
  if Source = nil then KillImgList else if Source is TsAlphaImageList then begin
    AcBeginUpdate;
    Clear;
    ImageList := TsAlphaImageList(Source);
    Masked := ImageList.Masked;
    ImageType := ImageList.ImageType;
    DrawingStyle := ImageList.DrawingStyle;
    ShareImages := ImageList.ShareImages;
    SetNewDimensions(ImageList.Handle);
    KillImgList;
    if not HandleAllocated then CreateImgList else ImageList_SetIconSize(Handle, Width, Height);
    BkColor := GetColor(ImageList_GetBkColor(ImageList.Handle));
    BlendColor := ImageList.BlendColor;
    CopyImages(ImageList);
    AcEndUpdate(False);
  end
  else inherited Assign(Source);
end;

procedure TsAlphaImageList.AssignTo(Dest: TPersistent);
var
  ImageList: TsAlphaImageList;
begin
  if Dest is TsAlphaImageList then begin
    ImageList := TsAlphaImageList(Dest);
    ImageList.AcBeginUpdate;
    ImageList.Masked := Masked;
    ImageList.ImageType := ImageType;
    ImageList.DrawingStyle := DrawingStyle;
    ImageList.ShareImages := ShareImages;
    ImageList.BlendColor := BlendColor;
    with ImageList do begin
      Clear;
      ImageList.KillImgList;
      SetNewDimensions(Self.Handle);
      if not HandleAllocated then CreateImgList else ImageList_SetIconSize(Handle, Width, Height);
      BkColor := GetColor(ImageList_GetBkColor(Self.Handle));
      ImageList.CopyImages(Self);
    end;
    ImageList.AcEndUpdate(False);
  end
  else inherited AssignTo(Dest);
end;

procedure TsAlphaImageList.CopyImages(const ImgList: TsAlphaImageList);
var
  i : integer;
  Ico : hIcon;
begin
  if not HandleAllocated then Exit;
  ImageList_SetBkColor(ImgList.Handle, CLR_NONE);

  if IsDuplicated then begin
    Items.Clear;
    for i := 0 to ImgList.Items.Count - 1 do begin
      with TsImgListItem(Items.Add) do begin
        ImageFormat := ImgList.Items[i].ImageFormat;
        PixelFormat := ImgList.Items[i].PixelFormat;
        ImgData.LoadFromStream(ImgList.Items[i].ImgData);
      end;
    end;
    GenerateStdList;
  end
  else begin
    Clear;
    ImageList_SetBkColor(Handle, CLR_NONE);
    for i := 0 to ImgList.Count - 1 do begin
      Ico := ImageList_GetIcon(ImgList.Handle, i, ILD_TRANSPARENT);
      ImageList_AddIcon(Handle, Ico);
      DestroyIcon(Ico);
    end;
  end;
end;

constructor TsAlphaImageList.Create(AOwner: TComponent);
begin
  inherited;
  FItems := TsImgListItems.Create(Self);
  FBkColor := clNone;
  FUseCache := True;
  DoubleData := True;
end;

procedure TsAlphaImageList.CreateImgList;
begin
  Handle := ImageList_Create(Width, Height, ILC_COLOR32 or (Integer(Masked) * ILC_MASK), 0, AllocBy);
end;

destructor TsAlphaImageList.Destroy;
begin
  FreeAndNil(FItems);
  inherited;
end;

procedure TsAlphaImageList.DoDraw(Index: Integer; Canvas: TCanvas; X, Y: Integer; Style: Cardinal; Enabled: Boolean);
var
  Ico : hIcon;
  TmpBmp, Bmp : TBitmap;
begin
  if HandleAllocated and (Index >= 0) then begin
    if (Items.Count > Index) then begin
      case Items[Index].ImageFormat of
        ifPng : begin
          Bmp := CreateBitmap32(Index, Width, Height);
          if Bmp <> nil then begin
            try
              Bmp.Canvas.Lock;
              TmpBmp := CreateBmp32(Width, Height);
              TmpBmp.Canvas.Lock;
              try
                BitBlt(TmpBmp.Canvas.Handle, 0, 0, Width, Height, Canvas.Handle, X, Y, SRCCOPY);
                CopyBmp32(Rect(0, 0, Width, Height), Rect(0, 0, Width, Height), TmpBmp, Bmp, MakeCacheInfo(TmpBmp), False, clNone, 0, False);
                BitBlt(Canvas.Handle, X, Y, Width, Height, TmpBmp.Canvas.Handle, 0, 0, SRCCOPY);
              finally
                TmpBmp.Canvas.Unlock;
                FreeAndNil(TmpBmp);
              end;
              Bmp.Canvas.Unlock;
            finally
              FreeAndNil(Bmp);
            end;
          end;
        end;
        ifBmp32 : begin
          Bmp := CreateBitmap32(Index, Width, Height);
          if Bmp <> nil then begin
            try
              Bmp.Canvas.Lock;
              TmpBmp := CreateBmp32(Width, Height);
              TmpBmp.Canvas.Lock;
              try
                BitBlt(TmpBmp.Canvas.Handle, 0, 0, Width, Height, Canvas.Handle, X, Y, SRCCOPY);
                CopyBmp32(Rect(0, 0, Width, Height), Rect(0, 0, Width, Height), TmpBmp, Bmp, MakeCacheInfo(TmpBmp), False, clNone, 0, False);
                BitBlt(Canvas.Handle, X, Y, Width, Height, TmpBmp.Canvas.Handle, 0, 0, SRCCOPY);
              finally
                TmpBmp.Canvas.Unlock;
                FreeAndNil(TmpBmp);
              end;
              Bmp.Canvas.Unlock;
            finally
              FreeAndNil(Bmp);
            end;
          end;
        end;
        ifIco : begin
          ImageList_SetBkColor(Handle, CLR_NONE);
          Ico := ImageList_GetIcon(Handle, Index, ILD_TRANSPARENT);
          if (Ico > 0) then begin
            DrawIconEx(Canvas.Handle, X, Y, Ico, Width, Height, 0, 0, DI_NORMAL);
            DestroyIcon(Ico);
          end;
        end;
      end;
    end
    else begin
      ImageList_SetBkColor(Handle, CLR_NONE);
      Ico := ImageList_GetIcon(Handle, Index, ILD_TRANSPARENT);
      if (Ico > 0) then begin
        DrawIconEx(Canvas.Handle, X, Y, Ico, Width, Height, 0, 0, DI_NORMAL);
        DestroyIcon(Ico);
      end;
    end;
  end;
end;

procedure TsAlphaImageList.GenerateStdList;
var
  i : integer;
  Png : TPNGGraphic;
  Bmp : TBitmap;
  Icon : TIcon;
  Ico : hIcon;
begin
  if not HandleAllocated then Exit;
  AcChanging := True;
  Clear;
  for i := 0 to Items.Count - 1 do begin
    case Items[i].ImageFormat of
      ifPNG : begin
        Png := TPNGGraphic.Create;
        Items[i].ImgData.Seek(0, 0);
        Png.LoadFromStream(Items[i].ImgData);
        Items[i].OrigWidth := Png.Width;
        Items[i].OrigHeight := Png.Height;
{.$IFDEF DELPHI7UP}
        if IsNTFamily
          then Ico := MakeCompIcon(Png, ColorToRGB(TColor(ImageList_GetBkColor(Handle))))
          else
{.$ENDIF}
        Ico := MakeIcon32(Png);

        ImageList_AddIcon(Handle, Ico);
        DestroyIcon(Ico);
        FreeAndNil(Png);
      end;
      ifBMP32 : begin
        Bmp := TBitmap.Create;
        Items[i].ImgData.Seek(0, 0);
        Bmp.LoadFromStream(Items[i].ImgData);
        Items[i].OrigWidth := Bmp.Width;
        Items[i].OrigHeight := Bmp.Height;
{.$IFDEF DELPHI7UP}
        if IsNTFamily
          then Ico := MakeCompIcon(Bmp, ColorToRGB(TColor(ImageList_GetBkColor(Handle))))
          else
{.$ENDIF}
        Ico := MakeIcon32(Bmp);

        ImageList_AddIcon(Handle, Ico);
        DestroyIcon(Ico);
        FreeAndNil(Bmp);
      end;
      ifICO : begin
        Icon := TIcon.Create;
        Items[i].ImgData.Seek(0, 0);
        Icon.LoadFromStream(Items[i].ImgData);
        Items[i].OrigWidth := Icon.Width;
        Items[i].OrigHeight := Icon.Height;
        ImageList_AddIcon(Handle, Icon.Handle);
        FreeAndNil(Icon);
      end;
    end;
  end;
  if Items.Count > 0 then begin
    StdListIsGenerated := True;
    if not IsDuplicated then Items.Clear;
  end;
  AcChanging := False;
end;

procedure CorrectPixelFrmt(Bmp : TBitmap);
var
  x, y : integer;
  TransColor : TColor;
  C : TsColor_;
  S : PRGBAArray;
  Color : TsColor;
begin
  TransColor := clFuchsia;
  for Y := 0 to Bmp.Height - 1 do begin // Check if alphachannel if fully clear
    S := Bmp.ScanLine[Y];
    for X := 0 to Bmp.Width - 1 do begin
      C := S[X];
      if C.A <> 0 then begin
        TransColor := clNone;
        Break;
      end;
    end;
    if TransColor = clNone then Break;
  end;
  if TransColor = clFuchsia then begin
    TransColor := Bmp.Canvas.Pixels[0, Bmp.Height - 1];
    for X := 0 to Bmp.Width - 1 do for Y := 0 to Bmp.Height - 1 do begin
      Color.C := GetAPixel(Bmp, X, Y).C;
      if Color.C <> TransColor then begin
        Color.A := MaxByte;
        SetAPixel(Bmp, X, Y, Color);
      end;
    end;
  end;
end;

function TsAlphaImageList.GetBitmap32(Index: Integer; Image: TBitmap): Boolean;
var
  iInfo: TIconInfo;
  Ico : hIcon;
  TmpBmp : TBitmap;
  Png : TPNGGraphic;
  Bmp : TBitmap;
begin
  Result := False;
  if HandleAllocated and (Image <> nil) and (Index >= 0) and (Index < Count) then begin
    if IsDuplicated and (Index < Items.Count) and (Items[Index].ImgData.Size > 0) then begin // Using of original image if exists
      case Items[Index].ImageFormat of
        ifPNG : begin
          if FUseCache then begin
            if (Items[Index].CacheBmp <> nil) then begin
              if (Items[Index].CacheBmp.Width = Image.Width) and (Items[Index].CacheBmp.Height = Image.Height) then begin
                Image.Assign(Items[Index].CacheBmp);
                Result := True;
                Exit;
              end
              else FreeAndNil(Items[Index].CacheBmp); // Reset cache
            end;
          end;

          Png := TPNGGraphic.Create;
          Items[Index].ImgData.Seek(0, 0);
          if (Items[Index].OrigWidth <> Image.Width) or (Items[Index].OrigHeight <> Image.Height) then begin // If must be scaled
            Png.LoadFromStream(Items[Index].ImgData);
            Image.PixelFormat := pf32bit;
            Stretch(Png, Image, Image.Width, Image.Height, ftMitchell);
          end
          else begin
            Png.LoadFromStream(Items[Index].ImgData);
            Image.Assign(Png);
          end;
          FreeAndNil(Png);
          if Image.PixelFormat <> pf32bit then begin
            Image.PixelFormat := pf32bit;
            CorrectPixelFrmt(Image);
          end;
          // Make Cache
          if FUseCache then begin
            if (Image.Width = Width) and (Image.Height = Height) then begin
              Items[Index].CacheBmp := CreateBmp32(Image.Width, Image.Height);
              Items[Index].CacheBmp.Assign(Image);
            end;
          end;
          Result := True;
        end;
        ifBMP32 : begin
          if FUseCache then begin
            if (Items[Index].CacheBmp <> nil) then begin
              if (Items[Index].CacheBmp.Width = Image.Width) and (Items[Index].CacheBmp.Height = Image.Height) then begin
                Image.Assign(Items[Index].CacheBmp);
                Result := True;
                Exit;
              end
              else FreeAndNil(Items[Index].CacheBmp); // Reset cache
            end;
          end;

          Items[Index].ImgData.Seek(0, 0);
          if (Items[Index].OrigWidth <> Image.Width) or (Items[Index].OrigHeight <> Image.Height) then begin // If must be scaled
            Bmp := TBitmap.Create;
            Bmp.LoadFromStream(Items[Index].ImgData);
            Image.PixelFormat := pf32bit;
            Stretch(Bmp, Image, Image.Width, Image.Height, ftMitchell);
            FreeAndNil(Bmp);
          end
          else Image.LoadFromStream(Items[Index].ImgData);
          if Image.PixelFormat <> pf32bit then begin
            Image.PixelFormat := pf32bit;
            CorrectPixelFrmt(Image);
          end;
          // Make Cache
          if FUseCache then begin
            if (Image.Width = Width) and (Image.Height = Height) then begin
              Items[Index].CacheBmp := CreateBmp32(Image.Width, Image.Height);
              Items[Index].CacheBmp.Assign(Image);
            end;
          end;
          Result := True;
        end
        else begin
          Ico := ImageList_GetIcon(Handle, Index, ILD_NORMAL);
          if Ico = 0 then Exit;
          TmpBmp := CreateBmp32(Image.Width, Image.Height);
          if GetIconInfo(Ico, iInfo) then begin
            TmpBmp.Handle := iInfo.hbmColor;
            TmpBmp.HandleType := bmDIB;
            TmpBmp.PixelFormat := pf32bit;

            if (Win32MajorVersion < 6) and (GetBpp < 32) then begin // Update alpha channel
              CorrectPixelFrmt(TmpBmp);
            end;

            Image.Assign(TmpBmp);

            DeleteObject(iInfo.hbmMask);
            Result := True;
          end;
          FreeAndNil(TmpBmp);
          DestroyIcon(Ico);
        end;
      end;
    end
    else begin
      Ico := ImageList_GetIcon(Handle, Index, ILD_NORMAL);
      if Ico = 0 then Exit;
      TmpBmp := CreateBmp32(Image.Width, Image.Height);
      if GetIconInfo(Ico, iInfo) then begin
        TmpBmp.Handle := iInfo.hbmColor;
        TmpBmp.HandleType := bmDIB;
        TmpBmp.PixelFormat := pf32bit;

        if (Win32MajorVersion < 6) and (GetBpp < 32) then begin // Update alpha channel
          CorrectPixelFrmt(TmpBmp);
        end;

        Image.Assign(TmpBmp);

        DeleteObject(iInfo.hbmMask);
        Result := True;
      end;
      FreeAndNil(TmpBmp);
      DestroyIcon(Ico);
    end;
  end;
end;

function TsAlphaImageList.GetBkColor: TColor;
begin
  if FBkColor = clNone then Result := inherited BkColor else Result := FBkColor;
end;

function TsAlphaImageList.CreateBitmap32(Index: Integer; aWidth, aHeight : integer): TBitmap;
var
  iInfo: TIconInfo;
  Ico : hIcon;
  Png : TPNGGraphic;
  Bmp : TBitmap;
begin
  Result := nil;
  if HandleAllocated and (Index >= 0) and (Index < Count) then begin
    if IsDuplicated and (Index < Items.Count) and (Items[Index].ImgData.Size > 0) then begin // Using of original image if exists
      case Items[Index].ImageFormat of
        ifPNG : begin
          if FUseCache and (Items[Index].CacheBmp <> nil) then begin
            if (Items[Index].CacheBmp.Width = aWidth) and (Items[Index].CacheBmp.Height = aHeight) then begin
              Result := CreateBmp32(aWidth, aHeight);
              Result.Assign(Items[Index].CacheBmp);
              Exit;
            end
            else FreeAndNil(Items[Index].CacheBmp); // Reset cache
          end;

          if (Items[Index].OrigWidth <> aWidth) or (Items[Index].OrigHeight <> aHeight) then begin // If must be scaled
            Result := CreateBmp32(aWidth, aHeight);
            Png := TPNGGraphic.Create;
            Items[Index].ImgData.Seek(0, 0);
            Png.LoadFromStream(Items[Index].ImgData);
            Stretch(Png, Result, aWidth, aHeight, ftMitchell);
            FreeAndNil(Png);
          end
          else begin
            Result := TPNGGraphic.Create;
            Items[Index].ImgData.Seek(0, 0);
            Result.LoadFromStream(Items[Index].ImgData);
            if Result.PixelFormat <> pf32bit then begin
              Result.PixelFormat := pf32bit;
              CorrectPixelFrmt(Result);
            end;
          end;
          // Make Cache
          if FUseCache then begin
            Items[Index].CacheBmp := CreateBmp32(aWidth, aHeight);
            Items[Index].CacheBmp.Assign(Result);
          end;
        end;
        ifBMP32 : begin
          if FUseCache and (Items[Index].CacheBmp <> nil) then begin
            if (Items[Index].CacheBmp.Width = aWidth) and (Items[Index].CacheBmp.Height = aHeight) then begin
              Result := CreateBmp32(aWidth, aHeight);
              Result.Assign(Items[Index].CacheBmp);
              Exit;
            end
            else FreeAndNil(Items[Index].CacheBmp); // Reset cache
          end;

          if (Items[Index].OrigWidth <> aWidth) or (Items[Index].OrigHeight <> aHeight) then begin // If must be scaled
            Result := CreateBmp32(aWidth, aHeight);
            Bmp := TBitmap.Create;
            Items[Index].ImgData.Seek(0, 0);
            Bmp.LoadFromStream(Items[Index].ImgData);
            Stretch(Bmp, Result, aWidth, aHeight, ftMitchell);
            FreeAndNil(Bmp);
          end
          else begin
            Result := TBitmap.Create;
            Items[Index].ImgData.Seek(0, 0);
            Result.LoadFromStream(Items[Index].ImgData);
            if Result.PixelFormat <> pf32bit then begin
              Result.PixelFormat := pf32bit;
              CorrectPixelFrmt(Result);
            end;
          end;
          // Make Cache
          if FUseCache then begin
            Items[Index].CacheBmp := CreateBmp32(aWidth, aHeight);
            Items[Index].CacheBmp.Assign(Result);
          end;
        end
        else begin
          Ico := ImageList_GetIcon(Handle, Index, ILD_NORMAL);
          if Ico = 0 then Exit;
          Result := CreateBmp32(aWidth, aHeight);
          if GetIconInfo(Ico, iInfo) then begin
            Result.Handle := iInfo.hbmColor;
            Result.HandleType := bmDIB;
            Result.PixelFormat := pf32bit;
            if (Win32MajorVersion < 6) then begin // Update alpha channel
              if (GetBpp < 32) or ac_CheckEmptyAlpha then begin
                CorrectPixelFrmt(Result);
              end;
            end;
            DeleteObject(iInfo.hbmMask);
          end;
          DestroyIcon(Ico);
        end;
      end;
    end
    else begin
      Ico := ImageList_GetIcon(Handle, Index, ILD_NORMAL);
      if Ico = 0 then Exit;
      Result := CreateBmp32(aWidth, aHeight);
      if GetIconInfo(Ico, iInfo) then begin
        Result.Handle := iInfo.hbmColor;
        Result.HandleType := bmDIB;
        Result.PixelFormat := pf32bit;
        if (Win32MajorVersion < 6) then begin // Update alpha channel
          if (GetBpp < 32) or ac_CheckEmptyAlpha then begin
            CorrectPixelFrmt(Result);
          end;
        end;
        DeleteObject(iInfo.hbmMask);
      end;
      DestroyIcon(Ico);
    end;
  end;
end;

function TsAlphaImageList.IsDuplicated: boolean;
begin
  Result := DoubleData or (csDesigning in ComponentState);
end;

procedure TsAlphaImageList.KillImgList;
begin
  if HandleAllocated and not ShareImages then ImageList_Destroy(Handle);
  Handle := 0;
  Change;
end;

procedure TsAlphaImageList.Loaded;
begin
  inherited;
  if not HandleAllocated then CreateImgList;
  if not StdListIsGenerated then begin
    GenerateStdList;
    StdListIsGenerated := True; // Set the flag even if iconlist is empty
    Change;
  end;
end;

procedure TsAlphaImageList.LoadFromFile(const FileName: acString);
begin
  if not TryLoadFromfile(FileName) then MessageDlg('Cannot load ' + FileName + #13#10 + 'Invalid or unexpected image format.', mtError, [mbOk], 0);
end;

{$IFDEF DELPHI7UP}
procedure TsAlphaImageList.ReadData(Stream: TStream);
begin
// All data is in Items
end;

procedure TsAlphaImageList.WriteData(Stream: TStream);
begin
// All data is in Items
end;
{$ENDIF}

procedure TsAlphaImageList.SetBkColor(const Value: TColor);
begin
  FBkColor := Value;
  inherited BkColor := Value;
end;

procedure TsAlphaImageList.SetItems(const Value: TsImgListItems);
begin
  FItems.Assign(Value);
end;

procedure TsAlphaImageList.SetNewDimensions(Value: HImageList);
var
  AHeight, AWidth: Integer;
begin
  AWidth := Width;
  AHeight := Height;
  ImageList_GetIconSize(Value, AWidth, AHeight);
  Width := AWidth;
  Height := AHeight;
end;

function TsAlphaImageList.TryLoadFromfile(const FileName: acString) : boolean;
var
  Ico: HICON;
  iInfo : TIconInfo;
  Png : TPNGGraphic;
  iFormat : TsImageFormat;
  Bmp : TBitmap;
  X, Y : integer;
  BmpLine : PRGBAArray;
begin
  Result := False;
  Ico := 0;
  if not HandleAllocated or not GetImageFormat(FileName, iFormat) then Exit;

  if IsDuplicated then begin // If double data used
    with TsImgListItem(Items.Add) do begin
      ImgData.LoadFromFile(FileName);
      ImageFormat := iFormat;
      case iFormat of
        ifPNG : begin
          PixelFormat := pf32bit;
          Png := TPNGGraphic.Create;
          Png.LoadFromStream(ImgData);
          Ico := MakeIcon32(Png);
          FreeAndNil(Png);
        end;
        ifBMP32 : begin
          PixelFormat := pf32bit;
          Bmp := TBitmap.Create;
          Bmp.LoadFromStream(ImgData);
          Ico := MakeIcon32(Bmp);
          FreeAndNil(Bmp);
        end;
        ifICO : begin
{$IFDEF TNTUNICODE}
          Ico := ExtractIconW(hInstance, PacChar(FileName), 0);
{$ELSE}
          Ico := ExtractIcon(hInstance, PacChar(FileName), 0);
{$ENDIF}
          GetIconInfo(Ico, iInfo);
          Bmp := TBitmap.Create;
          Bmp.Handle := iInfo.hbmColor;
          Bmp.HandleType := bmDIB;
          PixelFormat := pf24bit;

          if (Bmp.PixelFormat = pf32bit) then begin // Check the alpha channel
            for Y := 0 to Bmp.Height - 1 do begin
              BmpLine := Bmp.ScanLine[Y];
              for X := 0 to Bmp.Width - 1 do if BmpLine[X].A <> 0 then begin
                PixelFormat := pf32bit;
                Break;
              end;
              if PixelFormat = pf32bit then Break;
            end;
          end;

          FreeAndNil(Bmp);
          DeleteObject(iInfo.hbmColor);
          DeleteObject(iInfo.hbmMask);
        end;
      end;
    end;
  end
  else begin
    case iFormat of
      ifPNG : begin
        Png := TPNGGraphic.Create;
        Png.LoadFromFile(FileName);
        Ico := MakeIcon32(Png);
        FreeAndNil(Png);
      end;
      ifBMP32 : begin
        Bmp := TBitmap.Create;
        Bmp.LoadFromFile(FileName);
        Ico := MakeIcon32(Bmp);
        FreeAndNil(Bmp);
      end;
      ifICO : begin
{$IFDEF TNTUNICODE}
        Ico := ExtractIconW(hInstance, PacChar(FileName), 0);
{$ELSE}
        Ico := ExtractIcon(hInstance, PacChar(FileName), 0);
{$ENDIF}
      end;
    end;
  end;

  if Ico <> 0 then begin
    Result := ImageList_AddIcon(Handle, Ico) > -1;
    DestroyIcon(Ico);
  end;
  Change;
end;

procedure TsAlphaImageList.ItemsClear;
var
  i : integer;
begin
  for i := 0 to Items.Count - 1 do Items[i].ImgData.Clear;
end;

procedure TsAlphaImageList.Change;
var
  Ico, NewIco: HICON;
  iInfo : TIconInfo;
  Bmp : TBitmap;
  X, Y : integer;
  BmpLine : PRGBAArray;
  i, c, h, w : integer;
  b : boolean;
begin
  if AcChanging then Exit;
  if HandleAllocated and not (csLoading in ComponentState) and StdListIsGenerated then begin
    if not (IsDuplicated and (Count <= Items.Count)) or (csDesigning in ComponentState) then inherited;
    if not (csDesigning in ComponentState) then begin
      if IsDuplicated and (Count <= Items.Count) {If icon was not added using AddIcon or other std. way (not stored in Items)} then begin
        if (Count < Items.Count) then begin
          AcChanging := True;
          GenerateStdList;
          AcChanging := False;
        end;
        inherited;
      end
      else begin
        c := ImageList_GetImageCount(Handle) - 1;
        if c > -1 then begin
          Bmp := TBitmap.Create;        
          for i := 0 to c do begin
            Ico := ImageList_GetIcon(Handle, i, ILD_NORMAL);
            GetIconInfo(Ico, iInfo);
            DestroyIcon(Ico);
            Bmp.Handle := iInfo.hbmColor;
            Bmp.HandleType := bmDIB;
            b := False;
            h := Bmp.Height - 1;
            w := Bmp.Width - 1;
            Bmp.PixelFormat := pf32bit;
            for Y := 0 to h do begin // Check if AlphaChannel is empty
              BmpLine := Bmp.ScanLine[Y];
              for X := 0 to w do if BmpLine[X].A <> 0 then begin
                b := True;
                Break;
              end;
              if b then Break;
            end;
            if not b then begin
              for Y := 0 to h do begin
                BmpLine := Bmp.ScanLine[Y];
                for X := 0 to w do if BmpLine[X].C <> sFuchsia.C then BmpLine[X].A := $FF;
              end;
              iInfo.hbmColor := Bmp.Handle;

              NewIco := CreateIconIndirect(iInfo);
              ImageList_ReplaceIcon(Handle, i, NewIco);
              DestroyIcon(NewIco);
            end;
            DeleteObject(iInfo.hbmColor);
            DeleteObject(iInfo.hbmMask);
          end;
          FreeAndNil(Bmp);
        end;
      end;
    end;
  end;
end;

procedure TsAlphaImageList.AcBeginUpdate;
begin
  AcChanging := True;
end;

procedure TsAlphaImageList.AcEndUpdate(DoChange : boolean = True);
begin
  AcChanging := False;
  if DoChange then Change;
end;

procedure TsAlphaImageList.SetUseCache(const Value: boolean);
var
  i : integer;
begin
  FUseCache := Value;
  for i := 0 to Items.Count - 1 do begin
    if Items[i].CacheBmp <> nil then FreeAndNil(Items[i].CacheBmp);
  end;
end;

procedure TsAlphaImageList.MoveItem(CurIndex, NewIndex: integer);
begin
  Items[CurIndex].Index := NewIndex;
  Move(CurIndex, NewIndex);
//  Change;
end;

function TsAlphaImageList.Add(Image, Mask: TBitmap): Integer;
var
  Ico : hIcon;
  C : TsColor;
begin
  if IsDuplicated then begin // If double data used
    with TsImgListItem(Items.Add) do begin
      if Image.PixelFormat <> pf32bit then begin
        Image.PixelFormat := pf32bit;
        if Image.Transparent then begin
          C.C := Image.TransparentColor;
          C.A := 0;
          FillAlphaRect(Image, Rect(0, 0, Image.Width, Image.Height), MaxByte, C.C);
        end
        else FillAlphaRect(Image, Rect(0, 0, Image.Width, Image.Height), MaxByte, clNone);
      end;
      Image.SaveToStream(ImgData);
      ImageFormat := ifBMP32;
      PixelFormat := pf32bit;
      Ico := MakeIcon32(Image);
    end;
  end
  else begin
    Ico := MakeIcon32(Mask);
  end;

  if Ico <> 0 then begin
    Result := ImageList_AddIcon(Handle, Ico);
    DestroyIcon(Ico);
  end
  else Result := -1;
  Change;
end;

{ TsImgListItems }

constructor TsImgListItems.Create(AOwner: TsAlphaImageList);
begin
  inherited Create(TsImgListItem);
  FOwner := AOwner;
end;

destructor TsImgListItems.Destroy;
begin
  inherited Destroy;
  FOwner := nil;
end;

function TsImgListItems.GetItem(Index: Integer): TsImgListItem;
begin
  Result := TsImgListItem(inherited GetItem(Index));
end;

function TsImgListItems.GetOwner: TPersistent;
begin
  Result := FOwner;
end;

procedure TsImgListItems.SetItem(Index: Integer; Value: TsImgListItem);
begin
  inherited SetItem(Index, Value);
end;

{ TsImgListItem }

procedure TsImgListItem.Assign(Source: TPersistent);
begin
  if Source <> nil then begin
    ImageFormat := TsImgListItem(Source).ImageFormat;
    PixelFormat := TsImgListItem(Source).PixelFormat;
    OrigWidth   := TsImgListItem(Source).OrigWidth;
    OrigHeight  := TsImgListItem(Source).OrigHeight;
    ImgData.LoadFromStream(TsImgListItem(Source).ImgData);
  end
  else inherited;
end;

procedure TsImgListItem.AssignTo(Dest: TPersistent);
begin
  if Dest <> nil then begin
    TsImgListItem(Dest).ImageFormat := ImageFormat;
    TsImgListItem(Dest).PixelFormat := PixelFormat;
    TsImgListItem(Dest).OrigWidth := OrigWidth;
    TsImgListItem(Dest).OrigHeight := OrigHeight;
    TsImgListItem(Dest).ImgData.LoadFromStream(ImgData);
  end
  else inherited;
end;

constructor TsImgListItem.Create(Collection: TCollection);
begin
  inherited Create(Collection);
  FOwner := TsImgListItems(Collection);
  ImgData := TMemoryStream.Create;
  FPixelFormat := pf32bit;
end;

procedure TsImgListItem.DefineProperties(Filer: TFiler);
begin
  inherited DefineProperties(Filer);
  Filer.DefineBinaryProperty('ImgData', ReadData, WriteData, True);
end;

destructor TsImgListItem.Destroy;
begin
  FreeAndNil(ImgData);
  if CacheBmp <> nil then FreeAndNil(CacheBmp);
  inherited Destroy;
end;

procedure TsImgListItem.ReadData(Reader: TStream);
begin
  ImgData.LoadFromStream(Reader);
end;

procedure TsImgListItem.WriteData(Writer: TStream);
begin
  ImgData.SaveToStream(Writer);
end;

{ TsVirtualImageList }

procedure TsVirtualImageList.AcBeginUpdate;
begin
  AcChanging := True;
end;

procedure TsVirtualImageList.AcEndUpdate(DoChange: boolean);
begin
  AcChanging := False;
  UpdateList;
  if DoChange then Change;
end;

procedure TsVirtualImageList.AfterConstruction;
begin
  inherited;
  if not (csLoading in ComponentState) then begin
    if not HandleAllocated then CreateImgList;
    UpdateList(False);
  end;
end;

procedure TsVirtualImageList.Change;
begin
  if AcChanging then Exit;
  inherited;
end;

procedure TsVirtualImageList.ClearItems;
var
  i : integer;
begin
  for i := 0 to Length(CachedImages) - 1 do begin
    if CachedImages[i] <> nil then FreeAndNil(CachedImages[i]);
  end;
  SetLength(CachedImages, 0);
end;

function TsVirtualImageList.Count: integer;
begin
  if FAlphaImageList <> nil then Result := FAlphaImageList.Count else Result := 0;
end;

constructor TsVirtualImageList.Create(AOwner: TComponent);
begin
  inherited;
  FHeight := 16;
  FWidth := 16;
  FUseCache := True;
  DrawingStyle := dsTransparent;
  FImageChangeLink := TChangeLink.Create;
  FImageChangeLink.OnChange := ImageListChange;
end;

procedure TsVirtualImageList.CreateImgList;
begin
  Handle := ImageList_Create(Width, Height, ILC_COLOR32 or (Integer(Masked) * ILC_MASK), 0, AllocBy);
end;

destructor TsVirtualImageList.Destroy;
begin
  FreeAndNil(FImageChangeLink);
  ClearItems;
  inherited;
end;

procedure TsVirtualImageList.DoDraw(Index: Integer; Canvas: TCanvas; X, Y: Integer; Style: Cardinal; Enabled: Boolean);
var
  TmpBmp, IcoBmp : TBitmap;
begin
  if HandleAllocated and (Index >= 0) then begin
    if FUseCache then begin
      if (Count > Index) then begin
        if CachedImages[Index] = nil then FAlphaImageList.GetBitmap32(Index, CachedImages[Index]);
        if (CachedImages[Index] <> nil) then begin
          TmpBmp := CreateBmp32(Width, Height);
          TmpBmp.Canvas.Lock;
          try
            BitBlt(TmpBmp.Canvas.Handle, 0, 0, Width, Height, Canvas.Handle, X, Y, SRCCOPY);
            CopyBmp32(Rect(0, 0, Width, Height), Rect(0, 0, Width, Height), TmpBmp, CachedImages[Index], MakeCacheInfo(TmpBmp), False, clNone, 0, False);
            BitBlt(Canvas.Handle, X, Y, Width, Height, TmpBmp.Canvas.Handle, 0, 0, SRCCOPY);
          finally
            TmpBmp.Canvas.Unlock;
            FreeAndNil(TmpBmp);
          end;
        end;
      end;
    end
    else begin
      if (Count > Index) then begin
        TmpBmp := CreateBmp32(Width, Height);
        IcoBmp := CreateBmp32(Width, Height);
        TmpBmp.Canvas.Lock;
        try
          FAlphaImageList.GetBitmap32(Index, IcoBmp);
          BitBlt(TmpBmp.Canvas.Handle, 0, 0, Width, Height, Canvas.Handle, X, Y, SRCCOPY);
          CopyBmp32(Rect(0, 0, Width, Height), Rect(0, 0, Width, Height), TmpBmp, IcoBmp, MakeCacheInfo(TmpBmp), False, clNone, 0, False);
          BitBlt(Canvas.Handle, X, Y, Width, Height, TmpBmp.Canvas.Handle, 0, 0, SRCCOPY);
        finally
          TmpBmp.Canvas.Unlock;
          FreeAndNil(TmpBmp);
          FreeAndNil(IcoBmp);
        end;
      end;
    end;
  end;
end;

procedure TsVirtualImageList.GenerateStdList;
var
  i : integer;
  Ico : hIcon;
  Bmp : TBitmap;
begin
  if not HandleAllocated then Exit;
  AcChanging := True;
  ClearItems;
  Clear;

  if (FAlphaImageList <> nil) then begin
    if FUseCache then begin
      // Make empty cache
      SetLength(CachedImages, FAlphaImageList.Count);
      // Fill cache if images are big
      for i := 0 to FAlphaImageList.Count - 1 do begin
        if CachedImages[i] = nil then CachedImages[i] := CreateBmp32(Width, Height) else begin
          CachedImages[i].Width := Width;
          CachedImages[i].Height := Height;
        end;
        if FAlphaImageList.GetBitmap32(i, CachedImages[i]) then begin
          Ico := MakeIcon32(CachedImages[i]);
          ImageList_AddIcon(Handle, Ico);
          DestroyIcon(Ico);
        end
        else CachedImages[i] := nil;
      end;
    end
    else begin
      Bmp := CreateBmp32(Width, Height);
      for i := 0 to FAlphaImageList.Count - 1 do begin
        if FAlphaImageList.GetBitmap32(i, Bmp) then begin
          Ico := MakeIcon32(Bmp);
          ImageList_AddIcon(Handle, Ico);
          DestroyIcon(Ico);
        end
        else CachedImages[i] := nil;
      end;
      Bmp.Free;
    end;
  end;

  StdListIsGenerated := True;
  AcChanging := False;
end;

function TsVirtualImageList.GetBitmap32(Index: Integer; Image: TBitmap): Boolean;
begin
  Result := False;
  if HandleAllocated and (Index >= 0) then begin
    if FUseCache then begin
      if (Count > Index) then begin
        if CachedImages[Index] = nil then FAlphaImageList.GetBitmap32(Index, CachedImages[Index]);
        if (CachedImages[Index] <> nil) then begin
          Image.Assign(CachedImages[Index]);
        end;
      end;
    end
    else begin
      if (FAlphaImageList <> nil) and (GetImageCount(FAlphaImageList) > Index) then begin
        FAlphaImageList.GetBitmap32(Index, Image);
        Result := True;
      end;
    end;
  end;
end;

procedure TsVirtualImageList.ImageListChange(Sender: TObject);
begin
  UpdateList;
end;

procedure TsVirtualImageList.KillImgList;
begin
  if HandleAllocated and not ShareImages then ImageList_Destroy(Handle);
  Handle := 0;
  Change;
end;

procedure TsVirtualImageList.Loaded;
begin
  inherited;
  if not HandleAllocated then CreateImgList;
  UpdateList(False);
end;

procedure TsVirtualImageList.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent = FAlphaImageList) then AlphaImageList := nil;
end;

procedure TsVirtualImageList.SetAlphaImageList(const Value: TsAlphaImageList);
begin
  if FAlphaImageList <> nil then FAlphaImageList.UnRegisterChanges(FImageChangeLink);
  FAlphaImageList := Value;
  if FAlphaImageList <> nil then FAlphaImageList.RegisterChanges(FImageChangeLink);
  UpdateList;
end;

procedure TsVirtualImageList.SetHeight(const Value: integer);
begin
  if FHeight <> Value then begin
    FHeight := Value;
    inherited Height := Value;
    UpdateList;
  end;
end;

procedure TsVirtualImageList.SetUseCache(const Value: boolean);
begin
  FUseCache := Value;
  UpdateList;
end;

procedure TsVirtualImageList.SetWidth(const Value: integer);
begin
  if FWidth <> Value then begin
    FWidth := Value;
    inherited Width := Value;
    UpdateList;
  end;
end;

procedure TsVirtualImageList.UpdateList;
begin
  if (IgnoreGenerated or not StdListIsGenerated) and not AcChanging then begin
    GenerateStdList;
    StdListIsGenerated := Count > 0;
    Change;
  end;
end;

end.
