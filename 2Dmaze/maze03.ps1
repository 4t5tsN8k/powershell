
# 変数初期化
# 自分の位置と向き
$my_x = 1
$my_y = 9
$my_direction = 8  # 向き 8北 6東 2南 4西 
$my_char = @("","","v","","<","",">","","^")  # 向き 8北 6東 2南 4西
$my_food = 50  # 食料　残り移動可能数
$my_scope = 3  # 見える範囲
$my_stepcount = 0  # 移動数
$my_mattockcnt = 1	# 壁が壊せる回数

# ゴールの位置
$goal_x = 9
$goal_y = 1
# 移動用変数
$dx = @(0,0,0,0,-1,0,1,0, 0)  # 向き 8北 6東 2南 4西
$dy = @(0,0,1,0, 0,0,0,0,-1)  # 向き 8北 6東 2南 4西

# 壁の文字
$kabemoji = "▓"

# 表示ウェイト時間（秒）
$waitcnt = 1

# 階
$floor = 1

function make-maze($floor) {

	$template=@(
		"▓▓▓▓▓▓▓▓▓▓▓",
		"▓         ▓",
		"▓ ▓ ▓ ▓ ▓ ▓",
		"▓         ▓",
		"▓ ▓ ▓ ▓ ▓ ▓",
		"▓         ▓",
		"▓ ▓ ▓ ▓ ▓ ▓",
		"▓         ▓",
		"▓ ▓ ▓ ▓ ▓ ▓",
		"▓         ▓",
		"▓▓▓▓▓▓▓▓▓▓▓"
	)

	# 乱数のリセット
	$rand  = Get-Random -SetSeed $(Get-Date -Format "ffff")
	# 乱数のリセットしない場合は下の2行をアンコメントする
	# $mazapattern = @(0,57,86,96,8,11,13,27,41)
	# $rand	 = Get-Random -SetSeed $mazapattern[$floor]

	$kabemoji = "▓"
	$map = @($template)
	for($y = 2;$y -lt $map.length-1;$y+=2) {
		for($x = 2;$x -lt $map[$y].length-1;$x+=2) {
			if($map[$y][$x] -eq $kabemoji) {
				$rand = Get-Random -Minimum 1 -Maximum 5
				if($rand -eq 1){$map[$y-1]=$map[$y-1].Remove($x,1);$map[$y-1]=$map[$y-1].insert($x,$kabemoji);}
				if($rand -eq 2){$map[$y]=$map[$y].Remove($x+1,1)  ;$map[$y]=$map[$y].insert($x+1,$kabemoji);  }
				if($rand -eq 3){$map[$y+1]=$map[$y+1].Remove($x,1);$map[$y+1]=$map[$y+1].insert($x,$kabemoji);}
				if($rand -eq 4){$map[$y]=$map[$y].Remove($x-1,1)  ;$map[$y]=$map[$y].insert($x-1,$kabemoji);  }
			}
		}
	}

	# 奇数階と偶数階で壁キャラを変える処理
	if($floor%2 -eq 0) {
		$global:kabemoji = "#"
		for($y = 0;$y -lt $map.length;$y+=1) {
			$map[$y] = $map[$y].replace("▓","#")
		}
	} else {
		$global:kabemoji = "▓"
	}

	return $map
}


function disp-maze($x,$y,$maze,$scope) {
	# 表示範囲の計算
	$mx = $x - $scope
	$my = $y - $scope
	if($mx -lt 0) {$mx = 0}
	if($my -lt 0) {$my = 0}

	# 表示範囲の計算　横の最大値
	$width = $x + $scope
	if($width -ge $maze[0].length) {
		$width = $maze[0].length - 1
	}

	# 表示範囲の計算　縦の最大値
	$height =  $y + $scope + 1
	if($height -gt $maze.length) {
		$height = $maze.length
	}

	# 枠の表示　上側
	write-host "+" -NoNewline
	for($i=0;$i -le $width-$mx+2;$i++){
		write-host "-" -NoNewline
	}
	write-host "+"

	# 自分の周りの表示
	for($yy = $my;$yy -lt $height;$yy++) {
		$temp_maze = ""
		for($xx=$mx;$xx -le $width;$xx++) {
			$temp_maze+=$maze[$yy][$xx]
		}
		write-host "| $temp_maze |"
	}

	# 枠の表示　下側
	write-host "+" -NoNewline
	for($i=0;$i -le $width-$mx+2;$i++){
		write-host "-" -NoNewline
	}
	write-host "+"
}



function checkEvent($my_food ,$my_scope ,$my_mattockcnt ,$auto) {

	# 乱数リセット
	$event = Get-Random -SetSeed $(Get-Date -Format "ffff")

	if($auto -eq $False) { # 自発的に見回した時とそれ以外で発生率を分ける
		write-host "周りを見回した..."
		Start-Sleep -Seconds $waitcnt
		$event = Get-Random -Minimum 0 -Maximum 20
	} else {
		$event = Get-Random -Minimum 0 -Maximum 100
	}

	if($event -lt 3) {

		write-host "壁の隙間にキノコが生えている..."
		Start-Sleep -Seconds $waitcnt
		$rand_food = Get-Random -Minimum 5 -Maximum 8
		write-host "食料を ${rand_food}個見つけました"
		$my_food+=$rand_food+1
		Start-Sleep -Seconds $waitcnt

	} elseif($event -eq 5) {

		write-host "壁の隙間にキノコが生えている..."
		Start-Sleep -Seconds $waitcnt
		write-host "食べられないようだ"
		Start-Sleep -Seconds $waitcnt

	} elseif($event -eq 10) {

		write-host "ネズミが足元を走り抜けた..."
		Start-Sleep -Seconds $waitcnt
		$rand_food = Get-Random -Minimum 3 -Maximum 5
		write-host "食料を ${rand_food}個失った"
		$my_food-=$rand_food+1
		Start-Sleep -Seconds $waitcnt

	} elseif($event -eq 11) {

		write-host "ネズミが足元を走り抜けた..."
		Start-Sleep -Seconds $waitcnt
		write-host "捕まえて食料にした"
		Start-Sleep -Seconds $waitcnt
		$rand_food = Get-Random -Minimum 5 -Maximum 8
		write-host "食料が ${rand_food}個増えた"
		$my_food+=$rand_food+1
		Start-Sleep -Seconds $waitcnt

	} elseif($event -eq 12) {

		write-host "ネズミが足元を走り抜けた..."
		Start-Sleep -Seconds $waitcnt
		write-host "松明を振り回して追い払った"
		Start-Sleep -Seconds $waitcnt
		write-host "松明の火が小さくなった"
		$my_scope-=1
		if($my_scope -eq 0){
			$my_scope = 1
		}
		Start-Sleep -Seconds $waitcnt

	} elseif($event -eq 15) {

		write-host "つまずいて食料と松明を落とした..."
		Start-Sleep -Seconds $waitcnt
		$rand_food = Get-Random -Minimum 3 -Maximum 5
		write-host "食料を ${rand_food}個失った"
		$my_food-=$rand_food+1
		Start-Sleep -Seconds $waitcnt
		write-host "松明の火が小さくなった"
		$my_scope-=1
		if($my_scope -eq 0){
			$my_scope = 1
		}
		Start-Sleep -Seconds $waitcnt

	} elseif($event -eq 16) {

		write-host "突風が吹いて松明の火が小さくなった..."
		$my_scope-=1
		Start-Sleep -Seconds $waitcnt
		if($my_scope -eq 0){
			write-host "...かと思ったら、天井から油が滴っていた"
			Start-Sleep -Seconds $waitcnt
			write-host "油を松明に擦り付けて火を大きくした"
			Start-Sleep -Seconds $waitcnt
			$my_scope = 3
		}
		Start-Sleep -Seconds $waitcnt

	} elseif($event -eq 17) {

		write-host "壁から木の根が生い茂っている..."
		Start-Sleep -Seconds $waitcnt
		if($my_scope -lt 3){
			$my_scope+=1
			write-host "はがして松明にした"
		} else {
			write-host "剝がそうとしたがビクともしなかった"
		}
		Start-Sleep -Seconds $waitcnt

	} else {

		if($auto -eq $False) {
			write-host "...何もなかった"
			Start-Sleep -Seconds $waitcnt
		}

	}

	return $my_food ,$my_scope ,$my_mattockcnt
}





while( $floor -le 10) {
	# マップを作る
	$maze = @()
	$maze = make-maze $floor

	# 自分キャラの上書き
	$maze[$my_y] = $maze[$my_y].Remove($my_x,1)
	$maze[$my_y] = $maze[$my_y].Insert($my_x,$my_char[$my_direction])
	# ゴールの上書き
	$maze[$goal_y] = $maze[$goal_y].Remove($goal_x,1)
	$maze[$goal_y] = $maze[$goal_y].Insert($goal_x,"G")

	$goalflg = $False
	$loopflg = $True
	while($loopflg -and -not($goalflg)) {
		# 画面のクリア
		cls

		# 画面表示
		disp-maze $my_x $my_y $maze $my_scope

		# 入力
		write-host "食料：${my_food} 松明：${my_scope} マトック：${my_mattockcnt} 移動数：${my_stepcount}歩 フロア：${floor}階"
		$keyinput = (read-host "どちらに進みますか　8:北 6:東 2:南 4:西 77:周りを見る 88:壁を壊す 99:終了") # 向き 8北 6東 2南 4西

		# 入力チェック
		if($keyinput -ne "0" -and $keyinput -ne "8" -and $keyinput -ne "6" -and $keyinput -ne "2" -and $keyinput -ne "4" -and $keyinput -ne "88" -and $keyinput -ne "77" -and $keyinput -ne "99") {
			# 該当の数字以外は無効とする
		  write-host "入力は半角数字 2,4,6,8,77,88,99のみ"
			continue;
		}

		if($keyinput -eq "0"){
			$maze
			continue;
		} 
	
		# 終了判定
		if($keyinput -eq "99"){
			$loopflg = $False
			continue;
		} 

		# 壁を壊す
		if($keyinput -eq "88"){
			if($my_mattockcnt -ge 1) {
				$tmp_my_x = $my_x + $dx[$my_direction]
				$tmp_my_y = $my_y + $dy[$my_direction]
				if($tmp_my_x -lt 1 -or $tmp_my_x -ge $maze[$tmp_my_x].length-1 -or $tmp_my_y -lt 1 -or $tmp_my_y -ge $maze.length-1){
					write-host "その壁は壊せなかった"
				} elseif($maze[$tmp_my_y][$tmp_my_x] -eq $kabemoji){
					write-host "壁を壊した"
					$my_mattockcnt-=1
					$maze[$tmp_my_y] = $maze[$tmp_my_y].Remove($tmp_my_x,1)
					$maze[$tmp_my_y] = $maze[$tmp_my_y].Insert($tmp_my_x," ")
				} else {
					write-host "壁はなかった"
				}
			}
			continue;
		} 

		# 周りを見る
		if($keyinput -eq "77"){
			$my_food ,$my_scope ,$my_mattockcnt = checkEvent $my_food $my_scope $my_mattockcnt $False
			continue;
		} 

		# 移動処理
		if($keyinput -ne $my_direction) {
			# 向きが違う場合、向きを変えるのみ
			$tmp_my_direction = $keyinput 
			$tmp_my_x = $my_x
			$tmp_my_y = $my_y
		} else {
			# 向きが同じなら進む
			$tmp_my_direction = $keyinput 
			$tmp_my_x = $my_x + $dx[$keyinput]
			$tmp_my_y = $my_y + $dy[$keyinput]
		}

		# 進む処理
		if($maze[$tmp_my_y][$tmp_my_x] -ne $kabemoji){# 壁の判定

			$my_stepcount+=1

			# 現在地を空白で消す
			$maze[$my_y] = $maze[$my_y].Remove($my_x,1)
			$maze[$my_y] = $maze[$my_y].Insert($my_x," ")

			# 位置移動
			$my_x = $tmp_my_x
			$my_y = $tmp_my_y
			$my_direction = $tmp_my_direction 

			# 表示
			$maze[$my_y] = $maze[$my_y].Remove($my_x,1)
			$maze[$my_y] = $maze[$my_y].Insert($my_x,$my_char[$my_direction])

			# ゴールの判定
			if($my_x -eq $goal_x -and $my_y -eq $goal_y) {
				write-host "ゴールに到着しました"
				disp-maze $my_x $my_y $maze $my_scope
				
				$goalflg = $True
			} else {
				# イベント発生チェック
				$my_food ,$my_scope ,$my_mattockcnt = checkEvent $my_food $my_scope $my_mattockcnt $True
			}

			# 終了の判定
			$my_food-=1
			if($my_food -lt 0 -and $loopflg -eq $True){
				write-host "食料が底をつきました"
				$loopflg = $False
			}

		}

	}

	if($goalflg) { # ゴールした時の処理

		# 上の階へ移動
		$floor+=1

		# 終了判定
		if($floor -eq 10) {
			write-host "10階に到着しました"			   
		} else {
			write-host "階段をあがって上の階に移動しました"
			write-host "★★★★★★★★★★★★"
			write-host "★★　フロア：${floor}階　★★"
			write-host "★★★★★★★★★★★★"
			Start-Sleep -Seconds 5
		}

		# ゴール地点を次のスタート地点にする
		if($my_y -eq 1) {
			$goal_y = $maze.length - 2;$goal_x = 1
		} else {
			$goal_y = 1;$goal_x = $maze[0].length - 2
		}

		#ゴールの変数をリセット
		$goalflg = $False
		$my_mattockcnt = 1
	} else {
		write-host "終了します"
		$floor = 99
	}

}
