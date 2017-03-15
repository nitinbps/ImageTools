
function Get-ResizImage
{

    [OutputType([System.Drawing.Bitmap])]
    param(
        [Parameter(Mandatory=$false)]
        [int] $percentage = 100,

        [Parameter(Mandatory=$true)]
        [string] $path
    )

    # Read file
    $image = [System.Drawing.Image]::FromFile($path)

    # Set new width, height
    [int]$newWidth = $image.Width * $percentage /100;
    [int]$newHeight = $image.Height * $percentage /100;

    $destRect = [System.Drawing.Rectangle]::new(0, 0, $newWidth, $newHeight);
    
    $destImage = [System.Drawing.Bitmap]::new($newWidth, $newHeight);
    $destImage.SetResolution($image.HorizontalResolution, $image.VerticalResolution);

    $graphics = [System.Drawing.Graphics]::FromImage($destImage)
    
    #set quality metrics
    $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy;
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality;
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic;
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality;
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality;

    #create destination image
    $wrapMode = [System.Drawing.Imaging.ImageAttributes]::new()
    $wrapMode.SetWrapMode([System.Drawing.Drawing2D.WrapMode]::TileFlipXY)
    $graphics.DrawImage($image, $destRect, 0, 0, $image.Width,$image.Height, [System.Drawing.GraphicsUnit]::Pixel, $wrapMode);
    $graphics.Dispose()
    $wrapMode.Dispose()

    return $destImage;
}

function Get-Encoder
{
    [OutputType()]
    param(
        [Parameter(Mandatory=$true)]
        [System.Drawing.Imaging.ImageFormat]
        $format
    )
    [System.Drawing.Imaging.ImageCodecInfo[]] $codecs = [System.Drawing.Imaging.ImageCodecInfo]::GetImageDecoders();  
    foreach ($codec in $codecs)  
    {  
        if ($codec.FormatID -eq $format.Guid)  
        {  
            return $codec;  
        }  
    }  
    return $null; 
}

function Resize-Image
{
    param(
        [Parameter(Mandatory=$true)]
        [int] $percentage,

        [Parameter(Mandatory=$true)]
        [string] $path,

        [Parameter(Mandatory=$true)]
        [string] $outputPath
    )

    if( -not (Test-Path $path))
    {
        Write-Error "Path $path doesn't exist. Please specify a valid file path for directory path that contains .JPG files"
        return
    }

    if( -not (Test-Path $outputPath))
    {
        Write-Error "Path $outputPath doesn't exist."
        return
    }
    else
    {
    }

    Add-Type -AssemblyName System.Drawing

    $imageFiles = dir -Path $path -File

    foreach($imageFile in $imageFiles)
    {
        Write-Host "Processing File $($imageFile.FullName)" -Verbose
        $destUncompressedImage = Get-ResizImage -Path $imageFile.FullName -Percentage $percentage
        # compress the image
        $jpegFormat = [System.Drawing.Imaging.ImageFormat]::Jpeg
        $jpgEncoder = Get-Encoder -format $jpegFormat

        # create quality encoder
        [System.Drawing.Imaging.Encoder] $qualityEncoder = [System.Drawing.Imaging.Encoder]::Quality
        [System.Drawing.Imaging.EncoderParameters] $encodedParams = [System.Drawing.Imaging.EncoderParameters]::new(1)

        [System.Drawing.Imaging.EncoderParameter] $encodedParam = [System.Drawing.Imaging.EncoderParameter]::new($qualityEncoder, 50L)
        $encodedParams.Param[0] = $encodedParam

        #Save compressed File
        $destPath = join-path -Path $outputPath -ChildPath $($imageFile.Name)
        if( test-path $destPath)
        {
            del $destPath -Force -Verbose
        }
        $destUncompressedImage.Save($destPath, $jpgEncoder, $encodedParams)
    }

}