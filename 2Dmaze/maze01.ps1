$maze=@(
"***********",
"*       * *",
"* * *** * *",
"* **  *   *",
"*     *** *",
"* *** *G* *",
"* *   * * *",
"* * * * * *",
"*S*   *   *",
"***********"
)

# 変数初期化
# 自分の位置と向き
$my_x = -1
$my_y = -1
$my_direction = 0  # 向き 0北 1東 2南 3西 
$my_char = @("^",">","v","<")  # 向き 0北 1東 2南 3西
$my_scope = 3  # 見える範囲
# ゴールの位置
$goal_x = -1
$goal_y = -1
# 移動用変数
$dx = @(0,1,0,-1)
$dy = @(-1,0,1,0)

# スタートとゴールを探す
for($i = 0;$i -lt $maze.length;$i++) {
	for($j = 0;$j -lt $maze[$i].length;$j++) {
		if($maze[$i][$j] -eq "S") {
			$my_x = $j
			$my_y = $i
		}
		if($maze[$i][$j] -eq "G") {
			$goal_x = $j
			$goal_y = $i
		}
	}
}

# 自分キャラの上書き
$maze[$my_y] = $maze[$my_y].Remove($my_x,1)
$maze[$my_y] = $maze[$my_y].Insert($my_x,$my_char[$my_direction])

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

$endflg = $True
while($endflg) {
    # 画面表示
	disp-maze $my_x $my_y $maze $my_scope

	# 入力
	$keyinput = [int](read-host "どちらに進みますか　0:北 1:東 2:南 3:西 99:終了")

	# 入力チェック
	if($keyinput -ne "0" -and $keyinput -ne "1" -and$keyinput -ne "2" -and $keyinput -ne "3" -and $keyinput -ne "99") {
		# 該当の数字以外は無効とする
		continue;
	}
	
	# 終了判定
	if($keyinput -eq "99"){
		$endflg = $False
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
		$tmp_my_x = $my_x+$dx[$tmp_my_direction]
		$tmp_my_y = $my_y+$dy[$tmp_my_direction]
	}

	# 進む処理
	if($maze[$tmp_my_y][$tmp_my_x] -ne "*"){# 壁の判定
		# ゴールの判定
		if($maze[$tmp_my_y][$tmp_my_x] -eq "G"){
			write-host "ゴールに到着しました"
			$endflg = $False
		}

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

	}
}
