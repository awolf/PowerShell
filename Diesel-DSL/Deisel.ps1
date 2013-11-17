

function New-TodoList {
    param(
        [string]$ToDoListName,
        [scriptblock]$ScriptBlock
    )


    function New-TodoItem {
        param(
            [string]$Priority,
            [string]$Task
        )

        New-Object PSObject -Property @{
            ToDoListName = $ToDoListName
            Priority = $Priority
            Task = $Task
        }
    }

    & $ScriptBlock
}

function Use-Server {
    param(
        [string]$ServerName,
        [scriptblock]$ServerScriptBlock 
    )

    function Use-Database {
        param(
            [string]$DatabaseName,
            [scriptblock]$DatabaseScriptBlock
        )

        function Execute-Scripts {
            param(
                [scriptblock]$ExecuteScriptBlock
            )
            
            $script:targetfiles = @()
            $script:filelocation =""

            function Select-Files{
                param(
                    [string[]]$files 
                )
                $script:targetfiles = $files
                Write-Host  $targetfiles
            }

            function From-Location{
                param(
                    [string]$loc 
                )
                 $script:filelocation = $loc
            }

            & $ExecuteScriptBlock 
            
            Write-Host  "Deploy the report"
            Write-Host $script:targetfiles
            Write-Host $script:filelocation
        }

        & $DatabaseScriptBlock 
    }

    & $ServerScriptBlock 
}

Use-Server "sqlServer1" {
    Use-Database "webData" {
        Execute-Scripts {
            Select-Files "Proc1.sql", "Proc2.sql", "Proc3.sql"
            From-Location "\\server\share\dir1\dir2\"
        }
    }
}

Use-Server "reportServer1" {
    Move-Reports {
        Select-Reports "report1.rdl", "report2.rdl", "report3.rdl"
        From-Location "\\server\share\dir1\dir2\"
    }
}

Move-Reports -from "dev" -to "prod", {
    Select "report1.rdl", "report2.rdl", "report3.rdl"
    From "\mts\"
}