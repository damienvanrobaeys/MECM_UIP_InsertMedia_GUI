$SystemRoot = $env:SystemRoot
$OS_Version = "Windows 10 - 2004"
$Log_File = "$SystemRoot\Debug\Migration_Windows10.log"
$Global:Current_Folder = split-path $MyInvocation.MyCommand.Path
If(!(test-path $Log_File)){new-item $Log_File -type file -force | Out-Null}
Function Write_Log
	{
		param(
		$Message_Type,	
		$Message
		)
		
		$MyDate = "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)		
		Add-Content $Log_File  "$MyDate - $Message_Type : $Message"			
	}

Write_Log -Message_Type "INFO" -Message "The migration process to $OS_Version starts"

Function Start_Process
	{	
		Param(
				[Parameter(Mandatory=$false)]
				[string]$TSMBAutorun_Path						
			 )

		Try
			{
				start-process $TSMBAutorun_Path	
				Write_Log -Message_Type "INFO" -Message "Starting $TSMBAutorun_Path"				
			}
		Catch
			{
				Write_Log -Message_Type "ERROR" -Message "An issue occured while starting $TSMBAutorun_Path"							
			}
	}	


Function Show_WPF_Message
{
	[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')  				| out-null
	[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') 				| out-null
	[System.Reflection.Assembly]::LoadFrom("$Current_Folder\assembly\MahApps.Metro.dll")       				| out-null
	[System.Reflection.Assembly]::LoadFrom("$Current_Folder\assembly\MahApps.Metro.IconPacks.dll")      | out-null  

	function LoadXml ($global:filename)
	{
		$XamlLoader=(New-Object System.Xml.XmlDocument)
		$XamlLoader.Load($filename)
		return $XamlLoader
	}

	$XamlMainWindow=LoadXml("$Current_Folder\Upgrade_Warning.xaml")

	$Reader=(New-Object System.Xml.XmlNodeReader $XamlMainWindow)
	$Form=[Windows.Markup.XamlReader]::Load($Reader)

	$Logo_CM = $Form.findname("Logo_CM") 
	$Label_Close = $Form.findname("Label_Close") 
	$Main_Message = $Form.findname("Main_Message") 
	$Logo_Picture = $Form.findname("Logo_Picture") 
	$Main_Title = $Form.findname("Main_Title") 
	$Block_Header = $Form.findname("Block_Header") 
	$Block_Logo = $Form.findname("Block_Logo") 
	$Header_Image = $Form.findname("Header_Image") 
	$USB_Warning = $Form.findname("USB_Warning") 

	$XML_Config = "$Current_Folder\Warning_Config.xml"
	[xml]$Get_Config = get-content $XML_Config
	$Form.Title = $Get_Config.Config.GUI_Title
	$Get_Logo_Picture = $Get_Config.Config.Logo_File
	$Get_StatusBar_Text = $Get_Config.Config.GUI_StatusBar
	
	$Main_Message.Text = $Get_Config.Config.Text
	$Main_Title.Content = $Get_Config.Config.Title
	$Label_Close.Content = $Get_Config.Config.GUI_StatusBar	
	$Logo_Type = $Get_Config.Config.Image_Type
	
	$USB_Warning.Text = $Get_Config.Config.Media_Warning
	$USB_Warning.FontWeight = "Bold"
	$USB_Warning.Foreground = "Red"
	
	If($Logo_Type -eq "Header")
		{
			$Block_Header.Visibility = "Visible"
			$Block_Logo.Visibility = "Collapsed"	
			$Header_Image.Width = $Form.Width
			$Header_Image.Source = "$Current_Folder\images\$Get_Logo_Picture"
			
		}
	Else
		{
			$Block_Header.Visibility = "Collapsed"
			$Block_Logo.Visibility = "Visible"	
			$Logo_Picture.Source = "$Current_Folder\images\$Get_Logo_Picture"		
			
		}	
	$Form.ShowDialog() | Out-Null
}

Show_WPF_Message

Do
{
	$List_Disk = Get-volume | Where {(($_.DriveType -eq "Removable") -or ($_.DriveType -eq "CD-ROM"))}
	
	If($List_Disk -eq $null)
		{
			Show_WPF_Message
			Write_Log -Message_Type "ERROR" -Message "No standalone deployment media found"																	
			write-host "No standalone deployment media found"		
			sleep 1
		}
	Else
		{		
			ForEach($Disk in $List_Disk)
				{
					$DriveLetter = $Disk.DriveLetter
					$FriendlyName  = $Disk.FileSystemLabel
					$DriveType  = $Disk.DriveType			
					$Path = $DriveLetter + ":\SMS\bin\i386"
					$check_autorun = Get-childitem $Path -recurse -ErrorAction SilentlyContinue | where {$_.pschildname -like "TSMBAutorun.exe"} 
					If($check_autorun -ne $null)
						{
							$Get_TSMBAutorun_Path = $DriveLetter + ":\SMS\bin\i386\TSMBAutorun.exe" 
							Add-content $Log_File ""
							write-host "The file is located in $Get_TSMBAutorun_Path"		
							Write_Log -Message_Type "SUCCESS" -Message "The user has correctly plugged-in the standalone media"			
							Write_Log -Message_Type "SUCCESS" -Message "The file is located in $Get_TSMBAutorun_Path"																		
							Write_Log -Message_Type "INFO" -Message "The standalone media is plugged in drive: $DriveLetter"		
							Write_Log -Message_Type "INFO" -Message "Th friendly name of the media is: $FriendlyName"
							Write_Log -Message_Type "INFO" -Message "The media type is: $DriveType"								
							Write_Log -Message_Type "INFO" -Message "The migration process will start"
							Start_Process -TSMBAutorun_Path $Get_TSMBAutorun_Path
							exit	
						}
					Else
						{
							Show_WPF_Message
							Write_Log -Message_Type "ERROR" -Message "A standalone media is plugged-in but the file TSMBAutorun.exe dones not exist"																	
							write-host "A standalone media is plugged-in but the file TSMBAutorun.exe dones not exist"
							sleep 1		
						}
					break
				}  
		}
} 
While ($TSMBAutorun_Path -eq $null)            				