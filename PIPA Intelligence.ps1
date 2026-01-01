Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# ── API ────────────────────────────────────
$apiKey = "Your API KEY HERE"

$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Height="600" Width="800" AllowsTransparency="True" WindowStyle="None" Background="Transparent" 
        WindowStartupLocation="CenterScreen">
    <Border Background="#050505" BorderBrush="#00F2FF" BorderThickness="1">
        <Grid>
            <Grid.Background>
                <VisualBrush TileMode="Tile" Viewport="0,0,40,40" ViewportUnits="Absolute">
                    <VisualBrush.Visual>
                        <Path Data="M 0 40 L 0 0 L 40 0" Stroke="#0AFFFFFF" StrokeThickness="0.5" />
                    </VisualBrush.Visual>
                </VisualBrush>
            </Grid.Background>
            <Grid Margin="30">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>
                <StackPanel Grid.Row="0" Margin="0,0,0,20">
                    <TextBlock Text="Turn questions into clarity" Foreground="#00F2FF" FontSize="10" FontWeight="Bold" FontFamily="Consolas"/>
                    <TextBlock Text="[ PIPA Intelligence ]" Foreground="White" FontSize="22" FontWeight="ExtraBlack" FontFamily="Impact"/>
                    <Rectangle Fill="#00F2FF" Height="2" HorizontalAlignment="Left" Width="60" Margin="0,5,0,0"/>
                </StackPanel>

                <ScrollViewer Grid.Row="1" Name="ChatScroll" VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled" Background="Transparent">
                    <StackPanel Name="ChatPanel" Background="Transparent" Margin="0,0,0,10"/>
                </ScrollViewer>

                <Grid Grid.Row="2" Margin="0,20,0,0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="100"/>
                        <ColumnDefinition Width="100"/>
                    </Grid.ColumnDefinitions>
                    <TextBox Name="UserInput" Background="#111" Foreground="White" BorderBrush="#333" 
                             CaretBrush="#00F2FF" Padding="10" FontFamily="Consolas" FontSize="14" AcceptsReturn="False"/>
                    <Button Name="SendBtn" Grid.Column="1" Content="SEND" Background="#00F2FF" 
                            Foreground="Black" FontWeight="Bold" Margin="10,0,5,0" Cursor="Hand"/>
                    <Button Name="ClearBtn" Grid.Column="2" Content="CLEAR" Background="#444" 
                            Foreground="White" FontWeight="Bold" Cursor="Hand"/>
                </Grid>
            </Grid>
            <Button Name="CloseBtn" Content="[ CLOSE ]" Foreground="#FFF" FontSize="9" FontWeight="Bold" 
                    Background="Transparent" BorderThickness="0" HorizontalAlignment="Right" VerticalAlignment="Top" 
                    Margin="15" Cursor="Hand"/>
        </Grid>
    </Border>
</Window>
"@

# Load window
$window = [Windows.Markup.XamlReader]::Load([System.Xml.XmlNodeReader]::new([xml]$xaml))

# Controls
$chatPanel   = $window.FindName("ChatPanel")
$chatScroll  = $window.FindName("ChatScroll")
$userInput   = $window.FindName("UserInput")
$sendBtn     = $window.FindName("SendBtn")
$clearBtn    = $window.FindName("ClearBtn")
$closeBtn    = $window.FindName("CloseBtn")

$bc = New-Object System.Windows.Media.BrushConverter

# ── Message bubble creator ────────────────────────────────────────
function New-MessageBubble {
    param (
        [string]$Text,
        [string]$Sender,           # "USER" or "PIPA"
        [string]$Color
    )

    $alignment = if ($Sender -eq "USER") { "Right" } else { "Left" }
    $bgColor   = if ($Sender -eq "USER") { "#1E3A5F" } else { "#1A1A1A" }
    $margin    = if ($Sender -eq "USER") { "60,8,12,8" } else { "12,8,60,8" }

    $border = New-Object Windows.Controls.Border
    $border.Background       = $bc.ConvertFromString($bgColor)
    $border.BorderBrush      = $bc.ConvertFromString("#333")
    $border.BorderThickness  = "1"
    $border.CornerRadius     = "12"
    $border.Padding          = "14,10,14,10"
    $border.Margin           = $margin
    $border.HorizontalAlignment = $alignment

    $tb = New-Object Windows.Controls.TextBlock
    $tb.Text          = $Text
    $tb.TextWrapping  = "Wrap"
    $tb.Foreground    = $bc.ConvertFromString($Color)
    $tb.FontFamily    = New-Object Windows.Media.FontFamily("Consolas")
    $tb.FontSize      = 13.5
    $tb.TextAlignment = if ($Sender -eq "USER") { "Right" } else { "Left" }

    $border.Child = $tb
    return $border
}

# ── Thinking animation ────────────────────────────────────────────
$global:thinkingTimer = $null
$global:thinkingBlock = $null

function Start-Thinking {
    if ($global:thinkingTimer) { return }

    $global:thinkingBlock = New-Object Windows.Controls.TextBlock
    $global:thinkingBlock.Foreground = $bc.ConvertFromString("#666666")
    $global:thinkingBlock.FontFamily = New-Object Windows.Media.FontFamily("Consolas")
    $global:thinkingBlock.FontSize   = 13
    $global:thinkingBlock.Margin     = "20,12,20,12"
    $global:thinkingBlock.HorizontalAlignment = "Left"

    $chatPanel.Children.Add($global:thinkingBlock)

    $global:dots = 0
    $global:thinkingTimer = New-Object System.Windows.Threading.DispatcherTimer
    $global:thinkingTimer.Interval = [TimeSpan]::FromMilliseconds(400)

    $global:thinkingTimer.Add_Tick({
        $global:dots = ($global:dots + 1) % 5
        $dotStr = "." * $global:dots
        $global:thinkingBlock.Text = "PIPA is thinking$dotStr"
    })

    $global:thinkingTimer.Start()

    # Force immediate UI update
    $window.Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Render)
}

function Stop-Thinking {
    if ($global:thinkingTimer) {
        $global:thinkingTimer.Stop()
        $global:thinkingTimer = $null
    }
    if ($global:thinkingBlock -and $chatPanel.Children.Contains($global:thinkingBlock)) {
        $chatPanel.Children.Remove($global:thinkingBlock)
        $global:thinkingBlock = $null
    }
}

# ── Add message ───────────────────────────────────────────────────
function Add-Message {
    param (
        [string]$Text,
        [string]$Sender = "PIPA",
        [string]$Color = "#00F2FF"
    )

    $bubble = New-MessageBubble -Text $Text -Sender $Sender -Color $Color
    $chatPanel.Children.Add($bubble)

    # Small breathing room after user messages
    if ($Sender -eq "USER") {
        $spacer = New-Object Windows.Controls.Border
        $spacer.Height = 10
        $spacer.Background = [System.Windows.Media.Brushes]::Transparent
        $chatPanel.Children.Add($spacer)
    }

    $chatScroll.ScrollToEnd()
}

# ── Clear chat ────────────────────────────────────────────────────
function Clear-Chat {
    $chatPanel.Children.Clear()
    Add-Message -Text "[SYSTEM] PIPA Intelligence Connected..." -Color "#666666"
}

# ── Main send logic ───────────────────────────────────────────────
$SendMessage = {
    $prompt = $userInput.Text.Trim()
    if ([string]::IsNullOrEmpty($prompt)) { return }

    Add-Message -Text $prompt -Sender "USER" -Color "White"
    $userInput.Clear()

    # Show thinking immediately
    $window.Dispatcher.Invoke([Action]{ Start-Thinking }, [System.Windows.Threading.DispatcherPriority]::Render)

    try {
        $body = @{
            model    = "gemini-2.5-flash"
            messages = @(
                @{ role = "user"; content = $prompt }
            )
        } | ConvertTo-Json -Depth 10 -Compress

        $params = @{
            Method      = "Post"
            Uri         = "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions"
            Headers     = @{
                "Authorization" = "Bearer $apiKey"
                "Content-Type"  = "application/json"
            }
            Body        = [System.Text.Encoding]::UTF8.GetBytes($body)
        }

        $response = Invoke-RestMethod @params

        Stop-Thinking

        $aiReply = $response.choices[0].message.content.Trim()
        Add-Message -Text $aiReply -Color "#00F2FF"
    }
    catch {
        Stop-Thinking

        $errorMsg = $_.Exception.Message
        if ($_.Exception.Response) {
            try {
                $stream = $_.Exception.Response.GetResponseStream()
                $reader = New-Object System.IO.StreamReader($stream)
                $errBody = $reader.ReadToEnd()
                $errorMsg += " | $errBody"
            } catch {}
        }
        Add-Message -Text "[ERROR] $errorMsg" -Color "Red"
    }
}

# ── Event bindings ────────────────────────────────────────────────
$sendBtn.Add_Click($SendMessage)

$userInput.Add_KeyDown({ 
    if ($_.Key -eq 'Enter' -and -not $_.KeyboardDevice.Modifiers.HasFlag([System.Windows.Input.ModifierKeys]::Shift)) {
        & $SendMessage
        $_.Handled = $true
    }
})

$clearBtn.Add_Click({ Clear-Chat })

$closeBtn.Add_Click({ $window.Close() })

$window.Add_MouseLeftButtonDown({ $window.DragMove() })

# Initial state
Clear-Chat

$window.ShowDialog() | Out-Null