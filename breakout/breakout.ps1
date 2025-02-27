# キー入力の取得ができるようにする
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Keyboard
{
	[DllImport("user32.dll")]
	public static extern short GetAsyncKeyState(int vKey);
}
"@

$VK_SPACE = 0x20 # SPACEキー
$VK_LEFT = 0x25 # 上方向キー
$VK_RIGHT = 0x27 # 上方向キー

function onKeydown(){

	$key = ""
	if([Keyboard]::GetAsyncKeyState($VK_SPACE) -ne 0) {
		$key = "space"
	}
	if([Keyboard]::GetAsyncKeyState($VK_LEFT) -ne 0) {
		$key = "left"
	}
	if([Keyboard]::GetAsyncKeyState($VK_RIGHT) -ne 0) {
		$key = "right"
	}

	return $key
}


# ゲームの設定
$SCREEN_WIDTH = 40
$SCREEN_HEIGHT = 20
$BLOCK_CHAR = "#"

function initblocks(){
	# ブロックの初期化
	$blocks=@()
	$def_blocks=@(
		#0123456789012345678901234567890123456789
		"                                        ",
		"   ###    ###    ####    ##    #  #     ",
		"   #  #   #  #   #      #  #   # #      ",
		"   ###    ###    ####   ####   ##       ",
		"   #  #   #  #   #      #  #   # #      ",
		"   ###    #  #   ####   #  #   #  #     ",
		"                                        ",
		"    ##    #  #   #####                  ",
		"   #  #   #  #     #                    ",
		"   #  #   #  #     #                    ",
		"   #  #   #  #     #                    ",
		"    ##     ##      #                    "
	)


	for ($i = 0; $i -lt $def_blocks.length; $i++) {
		for ($j = 0; $j -lt $def_blocks[0].length; $j++) {
			if($def_blocks[$i][$j] -ne " ") {
				$blocks += @{X = $j; Y = $i+1}
			}
		}
	}
	return $blocks

}

function movebar($bar) {
	# キー入力
	$key = onKeydown
	if ($key -eq "left" -and $bar.x -gt 0) {
		$bar.x--
	}
	if ($key -eq "right" -and $bar.x -lt $SCREEN_WIDTH - $bar.char.length) {
		$bar.x++
	}

	if($bar.counter -gt 1) {
		$bar.counter-=1
		if($bar.char.indexof(" ") -eq -1) {
			$bar.char = "=====" + ("="*[Math]::Ceiling($bar.counter/100)) 
		} else {
			$bar.char = "==" + (" "*[Math]::Ceiling($bar.counter/100)) + "==" 
		}
	} else {
		$bar.char = "====="
	}

}

# ボールの処理
function moveball($balls,$bar,$blocks,$capsel,$updatecounter,[ref]$score) {
	if($updatecounter%3 -ne 0) { return }

	foreach($ball in $balls) {
		if($ball.y -ge $SCREEN_HEIGHT) {
			$ball.y = 999
			continue;
		}

		# ボールの移動
		$ball.x += $ball.dx
		$ball.y += $ball.dy

		# 衝突判定
		if ($ball.x -le 0) {# ボールと左壁 
			$ball.dx *= -1
			$ball.x = 1

		} elseif($ball.x -ge $SCREEN_WIDTH - 2) { # ボールと右壁
			$ball.dx *= -1
			$ball.x = $SCREEN_WIDTH - 2

		} elseif ($ball.y -le 1) { # 上の壁との衝突判定
			if((Get-Random -Maximum 5 -Minimum -0) -eq 0) {
				$ball.dx = (Get-Random -Maximum 3 -Minimum -2)
			}
			$ball.dy = 1
			$ball.y = 1

		} elseif ($ball.y -eq $bar.y) { # ボールとパドルとの衝突判定
			if($ball.x -eq $bar.x -or $ball.x -eq ($bar.x + $bar.char.length)) {
				# バーの端に当たる
				if($ball.dx -eq 0) {$ball.dx = (@(-3,3) | Get-Random)} 
				elseif ($ball.dx -gt 0) {$ball.dx = 3}
				else {$ball.dx = -3}
				$ball.dy = -1
			} elseif($ball.x -ge $bar.x -and $ball.x -le ($bar.x + $bar.char.length) -and $bar.char[($ball.x-$bar.x)] -ne " ") {
				# バーの真ん中近くにあたる
				$ball.dy = -1
				if((Get-Random -Maximum 5 -Minimum 0) -eq 0) {# ときどきランダムに跳ね返る
					$ball.dx = (Get-Random -Maximum 4 -Minimum -3)
					$ball.dy = (Get-Random -Maximum 0 -Minimum -2)
				}
			}
		} else {
			
			# ボールとブロックとの衝突判定
			for($i = 0;$i -lt $blocks.length;$i++) {
				$block = $blocks[$i]
				if ($ball.x -eq $block.X -and $ball.y -eq $block.Y) {
					$ball.dy *= -1
					if($updatecounter % 6 -eq 0 -or $ball.dx -eq 0 -or $ball.dx -ge 2 -or $ball.dx -le -2){ # ときどきランダムに跳ね返る
						$ball.dx = (Get-Random -Maximum 3 -Minimum -2)
					}
					$score.value += 10
					$block.y = 999

					if((Get-Random -Maximum 5 -Minimum 0) -eq 0 -and $capsel.y -eq 999) {
						$capsel.x=$ball.x
						$capsel.y=$ball.y
						$capsel.char=(@("B","W","D") | Get-Random )
					}
				}
			}
		}
	}
}

function movecapsel($capsel,$bar,$balls) {
	if($updatecounter%3 -ne 0) { return }

	if($capsel.y -lt $SCREEN_HEIGHT){

		if(($capsel.y -eq $bar.y)-and $capsel.x -ge $bar.x -and $capsel.x -le $bar.x+$bar.char.length){

			if($capsel.char -eq "B") { #ボールの分裂
				foreach($ball in $balls) {
					$cnt=0
					if($ball.y -ge $SCREEN_HEIGHT) {
						$tmp = @($balls | where-object{$_.y -lt $SCREEN_HEIGHT})
						$tmp=$tmp[0]
						$ball.x = $tmp.x
						$ball.y = $tmp.y
						$ball.dx = (-3,-2,-1,1,2,3) | Get-Random
						$ball.dy = (-1,1) | Get-Random
						$ball.counter = 0
						$cnt+=1
						if($cnt -ge 3){break}
					}
				}
			} elseif($capsel.char -eq "W") { #バーが伸びる
				$bar.counter = 300
				$bar.char = "========" 

			} elseif($capsel.char -eq "D") { #バーが分裂
				$bar.counter = 300
				$bar.char = "==" + (" "*[Math]::Ceiling($bar.counter/100)) + "=="  # "==   =="
				foreach($ball in $balls) {
					if($ball.dy -ge 2) {
						$ball.dy = 1
					} elseif($ball.dy -le -2) {
						$ball.dy = -1
					}
				}
			}

			$capsel.y=999	
		}

		$capsel.y+=1

	} else {
		$capsel.y=999
	}
}

function drawscreen($balls,$blocks,$capsel,$message){
	# 画面作成
	$screen = @()
	$line = "I" + "-" * ($SCREEN_WIDTH -2) + "I"
	$screen += @($line)
	$screen += @($line)
	for ($y = 2; $y -lt $SCREEN_HEIGHT; $y++) {
		$line = "I" + " " * ($SCREEN_WIDTH -2) + "I"

		foreach ($block in $blocks) {
			if ($block.Y -eq $y) {
				$line = $line.Remove($block.X, 1).Insert($block.X, $BLOCK_CHAR)
			}
		}
		$screen += @($line)
	}

	$screen[$bar.y] = $screen[$bar.y].Remove($bar.x, $bar.char.length)
	$screen[$bar.y] = $screen[$bar.y].Insert($bar.x, $bar.char)

	foreach($ball in $balls) {
		if($ball.y -ge 0 -and $ball.y -lt ($screen.Length -1)) {
			$screen[$ball.y] = $screen[$ball.y].Remove($ball.x, 1)
			$screen[$ball.y] = $screen[$ball.y].Insert($ball.x, $ball.char)
		}
	}
	
	if($capsel.y -lt $screen.Length-1){
		$screen[$capsel.y] = $screen[$capsel.y].Remove($capsel.x, 1)
		$screen[$capsel.y] = $screen[$capsel.y].Insert($capsel.x, $capsel.char)		
	}

	# 画面表示
	for($i=0;$i -lt $screen.length;$i++) {
		Write-Host ([char]0x1B + "[${i}d") -NoNewline
		Write-Host $screen[$i]
	}

	Write-Host ([char]0x1B + "[$($screen.length +1)d") -NoNewline
	Write-Host "Score: $score   $message" 
}



function play {

	# 初期状態
	# バー
	$bar = @{
		x = ($SCREEN_WIDTH / 2) - 3;# x座標
		y = $SCREEN_HEIGHT - 3; 	# y座標
		char = "====="; 			# 表示キャラクター
		counter = 0; 				#汎用カウンター
	}

	# ボール管理配列
	$balls = @(@{
			x = ($SCREEN_WIDTH / 2) - 3;# x座標
			y = $SCREEN_HEIGHT - 3;		# y座標
			dx=1;						# 移動量
			dy=-1;						# 移動量
			char = "o";					# 表示キャラクター
		})
	for($i=0;$i -lt 5;$i++){ #ダミーのボール
		$balls += @(@{x = ($SCREEN_WIDTH / 2) - 3;y = 999;dx=1;dy=-1;char = "o";counter = 0;})	
	}

	# カプセル Bボール分裂 Wバーが伸びる Dバーが分裂する
	$capsel = @{x=999;y=999;char="BWD";}

	# ブロックの初期化
	$blocks = initblocks

	# スコア
	$score = 0
	# 速さ　小さいほど速い
	$speed = 30
	# 更新回数カウンター　速度調節用
	$updatecounter = 0

	$message = ""

	# 画面クリア
	Clear-Host

	# ループ
	while ($true) {

		# バー移動
		movebar $bar $capsel
		# ボール移動
		moveball $balls $bar $blocks $capsel $updatecounter ([ref]$score)
		# カプセル移動
		movecapsel $capsel $bar $balls
		# 画面描画
		drawscreen $balls $blocks $capsel $message

		# ゲームオーバー判定
		if(($balls | Where-object {$_.y -lt $SCREEN_HEIGHT}).length -eq 0) {
			Write-Host "Game Over! Final Score: $score"
			Start-Sleep -Milliseconds ($speed*50)
			while($true) {
				$key = onKeydown
				if($key -eq "space") {
					break
				}
			}
			break  # ゲームオーバー
		}

		# クリア判定
		if(($blocks | Where-object{$_.y -eq 999}).Count -eq $blocks.length) {
			Write-Host "Game Clear! Final Score: $score"
			Start-Sleep -Milliseconds ($speed*50)
			while($true) {
				$key = onKeydown
				if($key -eq "space") {
					break
				}
			}
			break  # クリア
		}

		# 速度調整のスリープ
		Start-Sleep -Milliseconds $speed

		$updatecounter+=1
	}

}

function demo {
	# 乱数初期化
	get-random -setseed $(Get-Date -Format "HHmmss")

	# 初期状態
	# バー
	$bar = @{
		x = 1;# x座標
		y = $SCREEN_HEIGHT - 3; 	# y座標
		char = "====="; 			# 表示キャラクター
		counter = 0; 				#汎用カウンター
	}

	# ボール管理配列
	$balls = @(@{
			x = ($SCREEN_WIDTH / 2) - 3;# x座標
			y = $SCREEN_HEIGHT - 3;		# y座標
			dx=1;dy=-1;					# 移動量
			char = "o";					# 表示キャラクター
		})
	for($i=0;$i -lt 2;$i++){ #ダミーのボール
		$balls += @(@{x = (($SCREEN_WIDTH / 2) - $i);y = $SCREEN_HEIGHT - 3;dx=$i;dy=-1;char = "o";counter = 0;})	
	}
		
	# カプセル Bボール分裂 Wバーが伸びる Dバーが分裂する
	$capsel = @{x=999;y=999;char="BWD";}

	# ブロックの初期化
	$blocks = initblocks

	# スコア
	$score = 0
	# 速さ　小さいほど速い
	$speed = 30
	# 更新回数カウンター　速度調節用
	$updatecounter = 0

	$message = "Let's Play Braek out"

	# 画面クリア
	Clear-Host

	# 入力のクリア
	$key = onKeydown
	$key = ""

	# ループ
	while ($true) {
		$blocks = initblocks
		$bar.char = "============< HIT SPACE KEY >========="

		# ボール移動
		moveball $balls $bar $blocks $capsel $updatecounter ([ref]$score)
		$score = -9999

		# 画面描画
		drawscreen $balls $blocks $capsel $message
  
    $key =""
		$key = onKeydown
		if($key -eq "space") {
			Start-Sleep -Milliseconds ($speed*50)
			break
		}

		# 速度調整のスリープ
		Start-Sleep -Milliseconds $speed
		
		$updatecounter+=1
	}
	
}

while($true){
	demo
	play
}
