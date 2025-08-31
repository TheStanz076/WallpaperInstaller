Add-Type -AssemblyName PresentationFramework

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Arcane Wallpaper Codex" Height="300" Width="500"
        WindowStartupLocation="CenterScreen"
        Background="#1E1E2F" Foreground="White">
    <Grid Margin="20">
        <StackPanel HorizontalAlignment="Center" VerticalAlignment="Center" Orientation="Vertical" >
            <TextBlock Text="🧙 Arcane Wallpaper Codex" FontSize="20" FontWeight="Bold" Margin="0,0,0,20" HorizontalAlignment="Center"/>
            <Button Name="SummonButton" Content="Summon Wallpaper" Width="200" Height="40" Background="#3A3A5A" Foreground="White" FontWeight="Bold"/>
        </StackPanel>
    </Grid>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

$button = $window.FindName("SummonButton")
$button.Add_Click({
    [System.Windows.MessageBox]::Show("✨ Wallpaper spell cast!", "Arcane Codex")
})

$window.ShowDialog()