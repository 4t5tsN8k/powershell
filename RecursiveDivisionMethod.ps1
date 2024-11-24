# PowerShellによる棒倒し方のサンプルプログラム

$tempmaze=@(
    "▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓",
    "▓                 ▓",
    "▓ ▓ ▓ ▓ ▓ ▓ ▓ ▓ ▓ ▓",
    "▓                 ▓",
    "▓ ▓ ▓ ▓ ▓ ▓ ▓ ▓ ▓ ▓",
    "▓                 ▓",
    "▓ ▓ ▓ ▓ ▓ ▓ ▓ ▓ ▓ ▓",
    "▓                 ▓",
    "▓ ▓ ▓ ▓ ▓ ▓ ▓ ▓ ▓ ▓",
    "▓                 ▓",
    "▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓"
)

for($i = 1;$i -lt 10;$i++) {

    $i
    $kabemoji = "▓"
    $maze = @($tempmaze)
    for($y = 2;$y -lt $maze.length-1;$y+=2) {
	    for($x = 2;$x -lt $maze[$y].length-1;$x+=2) {
		    if($maze[$y][$x] -eq $kabemoji) {
			    $rand = Get-Random -Minimum 1 -Maximum 5
			    if($rand -eq 1){$maze[$y-1]=$maze[$y-1].Remove($x,1);$maze[$y-1]=$maze[$y-1].insert($x,$kabemoji);}
			    if($rand -eq 2){$maze[$y]=$maze[$y].Remove($x+1,1);$maze[$y]=$maze[$y].insert($x+1,$kabemoji);}
			    if($rand -eq 3){$maze[$y+1]=$maze[$y+1].Remove($x,1);$maze[$y+1]=$maze[$y+1].insert($x,$kabemoji);}
			    if($rand -eq 4){$maze[$y]=$maze[$y].Remove($x-1,1);$maze[$y]=$maze[$y].insert($x-1,$kabemoji);}
		    }
	    }
    }
    $maze
}
