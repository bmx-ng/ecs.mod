SuperStrict

Framework SDL.sdlrendermax2d
Import image.png
Import Ecs.Flecs
Import brl.random
Import Audio.AudioSDL
Import collections.queue
Import BRL.RamStream

Incbin "audio/asteroids_main.ogg"
Incbin "audio/asteroids_game_over.ogg"
Incbin "audio/shoot.ogg"
Incbin "audio/death.ogg"
Incbin "audio/hit_quiet.ogg"
Incbin "audio/thrust.ogg"

Incbin "images/ship.png"
Incbin "images/bullet.png"
Incbin "images/rock_large.png"
Incbin "images/rock_medium.png"
Incbin "images/rock_small.png"
Incbin "images/rock_tiny.png"
Incbin "images/particle.png"
Incbin "images/asteroids_logo.png"

AppTitle = "Asteroids ECS"

' shake things up a little
SeedRnd(Millisecs())

Graphics 800, 600

Global sounds:TSound[6]
sounds[0] = LoadSound("incbin::audio/asteroids_main.ogg", SOUND_STREAM)
sounds[1] = LoadSound("incbin::audio/asteroids_game_over.ogg", SOUND_STREAM)
sounds[2] = LoadSound("incbin::audio/shoot.ogg")
sounds[3] = LoadSound("incbin::audio/death.ogg")
sounds[4] = LoadSound("incbin::audio/hit_quiet.ogg")
sounds[5] = LoadSound("incbin::audio/thrust.ogg", SOUND_LOOP)

Global channels:THashMap<Int, TChannel> = New THashMap<Int, TChannel>
Global nextChannelId:Int = 1
Global thrustChannel:TChannel

Global images:TImage[] = New TImage[8]

images[0] = LoadImage("incbin::images/ship.png")
SetImageHandle(images[0], images[0].Width / 2, images[0].Height / 2)
images[1] = LoadImage("incbin::images/bullet.png")
SetImageHandle(images[1], images[1].Width / 2, images[1].Height / 2)
images[2] = LoadImage("incbin::images/rock_large.png")
SetImageHandle(images[2], images[2].Width / 2, images[2].Height / 2)
images[3] = LoadImage("incbin::images/rock_medium.png")
SetImageHandle(images[3], images[3].Width / 2, images[3].Height / 2)
images[4] = LoadImage("incbin::images/rock_small.png")
SetImageHandle(images[4], images[4].Width / 2, images[4].Height / 2)
images[5] = LoadImage("incbin::images/rock_tiny.png")
SetImageHandle(images[5], images[5].Width / 2, images[5].Height / 2)
images[6] = LoadImage("incbin::images/particle.png")
SetImageHandle(images[6], images[6].Width / 2, images[6].Height / 2)
images[7] = LoadImage("incbin::images/asteroids_logo.png")
SetImageHandle(images[7], images[7].Width / 2, images[7].Height / 2)

Const STATE_MENU:Int = 0
Const STATE_PLAYING:Int = 1
Const STATE_GAMEOVER:Int = 2
Const STATE_RETURNING_TO_MENU:Int = 3

Const ASTEROID_LARGE:Int = 0
Const ASTEROID_MEDIUM:Int = 1
Const ASTEROID_SMALL:Int = 2
Const ASTEROID_TINY:Int = 3

Const RESPAWN_X:Float = 400
Const RESPAWN_Y:Float = 300
Const PLAYER_SAFE_RADIUS:Float = 80

Const DIFFICULTY_NORMAL:Int = 0
Const DIFFICULTY_HARD:Int = 1

Global difficulty:Int = DIFFICULTY_NORMAL

Global gameState:Int = STATE_MENU
Global highScore:Int
Global score:Int
Global lives:Int
Global level:Int
Global player:ULong
Global gameOverInputDelay:Int

Global respawning:Int = False
Global respawnTimer:Int = 0

Global ASTEROID_RADIUS:Float[] = [24.0, 16.0, 8.0, 4.0]
Global ASTEROID_DEFAULT_SPEED:Float[] = [1, 1.4, 2, 3]

' Create the ECS world and register components, systems, and observers.
Global world:TEcsWorld = TEcsWorld.Create()

Global gameObjectTag:SEcsComponent = world.RegisterComponent("GameObject", 0, 0)

Global position:SEcsComponent = world.RegisterComponent("Position", SizeOf(SPosition), AlignOf(SPosition))
Global velocity:SEcsComponent = world.RegisterComponent("Velocity", SizeOf(SVelocity), AlignOf(SVelocity))
Global rotation:SEcsComponent = world.RegisterComponent("Rotation", SizeOf(SRotation), AlignOf(SRotation))
Global sprite:SEcsComponent = world.RegisterComponent("Sprite", SizeOf(SSprite), AlignOf(SSprite))
Global collider:SEcsComponent = world.RegisterComponent("Collider", SizeOf(SCollider), AlignOf(SCollider))
Global lifetime:SEcsComponent = world.RegisterComponent("Lifetime", SizeOf(SLifetime), AlignOf(SLifetime))
Global asteroid:SEcsComponent = world.RegisterComponent("Asteroid", SizeOf(SAsteroid), AlignOf(SAsteroid))
Global angularVelocity:SEcsComponent = world.RegisterComponent("AngularVelocity", SizeOf(SAngularVelocity), AlignOf(SAngularVelocity))
Global alpha:SEcsComponent = world.RegisterComponent("Alpha", SizeOf(SAlpha), AlignOf(SAlpha))
Global playerTag:SEcsComponent = world.RegisterComponent("Player", 0, 0)
Global bulletTag:SEcsComponent = world.RegisterComponent("Bullet", 0, 0)
Global particleTag:SEcsComponent = world.RegisterComponent("Particle", 0, 0)
Global finishedTag:SEcsComponent = world.RegisterComponent("Finished", 0, 0)
Global menuObjectTag:SEcsComponent = world.RegisterComponent("MenuObject", 0, 0)

Global music:SEcsComponent = world.RegisterComponent("Music", SizeOf(SMusic), AlignOf(SMusic))
Global volume:SEcsComponent = world.RegisterComponent("Volume", SizeOf(SVolume), AlignOf(SVolume))
Global fadeOut:SEcsComponent = world.RegisterComponent("FadeOut", SizeOf(SFadeOut), AlignOf(SFadeOut))

' Register struct metadata for components that are associated with BlitzMax structs. This allows the ECS to understand the layout of these components and how to access their fields.
' This is especially useful for serialization, reflection, and other advanced features that require knowledge of the component's structure.
' For example, flecs's explorer tool can use this metadata to display the fields of these components in real-time.
world.RegisterStructMeta("SPosition", position.id)
world.RegisterStructMeta("SVelocity", velocity.id)
world.RegisterStructMeta("SRotation", rotation.id)
world.RegisterStructMeta("SSprite", sprite.id)
world.RegisterStructMeta("SCollider", collider.id)
world.RegisterStructMeta("SLifetime", lifetime.id)
world.RegisterStructMeta("SAsteroid", asteroid.id)
world.RegisterStructMeta("SAngularVelocity", angularVelocity.id)
world.RegisterStructMeta("SAlpha", alpha.id)
world.RegisterStructMeta("SMusic", music.id)
world.RegisterStructMeta("SVolume", volume.id)
world.RegisterStructMeta("SFadeOut", fadeOut.id)

' Prefabs can be used to create entities with a predefined set of components and values.
' This is useful for things like bullets, enemies, or other objects that are created frequently and have the same initial state.
Global bulletPrefab:ULong = world.NewPrefab("BulletPrefab")
Local s:SSprite = New SSprite(1)
Local c:SCollider = New SCollider(4)
Local l:SLifetime = New SLifetime(1)
world.SetComponent(bulletPrefab, sprite, Varptr s)
world.SetComponent(bulletPrefab, collider, Varptr c)
world.SetComponent(bulletPrefab, lifetime, Varptr l)
world.SetComponent(bulletPrefab, bulletTag)

Global menuMusicEntity:ULong
Global gameOverMusicEntity:ULong

' Register systems for the game. Each system is associated with a set of components and will be called during the ECS update loop when entities with those components are present.
world.RegisterSystem("PlayerInput", EcsOnUpdate, [position.id, velocity.id, rotation.id, playerTag.id], PlayerInput)
world.RegisterSystem("Move", EcsOnUpdate, [position.id, velocity.id], Move)
world.RegisterSystem("WrapScreen", EcsOnUpdate, [position.id], WrapScreen)
world.RegisterSystem("Lifetime", EcsOnUpdate, [lifetime.id], LifetimeSystem)
world.RegisterSystem("Render", EcsOnUpdate, [position.id, sprite.id, rotation.id], Render)
world.RegisterSystem("Rotate", EcsOnUpdate, [rotation.id, angularVelocity.id], Rotate)
world.RegisterSystem("Fade", EcsOnUpdate, [lifetime.id, alpha.id], Fade)
world.RegisterSystem("RenderAlpha", EcsOnUpdate, [position.id, sprite.id, alpha.id], RenderAlpha)

world.RegisterSystem("MusicUpdate", EcsOnUpdate, [music.id, volume.id], MusicUpdate)

Global finishedMusicQueue:TQueue<ULong> = New TQueue<ULong>
' Register an observer for when music finishes playing. This allows the game to respond to the event, such as starting the next track or looping the current one.
world.RegisterObserver("OnMusicFinished", EcsOnAdd, [music.id, finishedTag.id], OnMusicFinished)

Global bulletQuery:TEcsQuery = world.CreateQuery([position.id, collider.id, velocity.id, bulletTag.id])
Global asteroidQuery:TEcsQuery = world.CreateQuery([position.id, collider.id, asteroid.id])
Global gameObjectQuery:TEcsQuery = world.CreateQuery([gameObjectTag.id])
Global menuObjectQuery:TEcsQuery = world.CreateQuery([menuObjectTag.id])

' Enable the REST server for the ECS world.
' This allows external tools to connect to the game and inspect or modify the ECS state in real-time, which is useful for debugging and development.
world.EnableRestServer()

ShowMenu()

While Not KeyDown(Key_Escape)

	Cls

	world.Update(1.0 / 60.0)
	FlushFinishedMusicQueue()

	Select gameState
		Case STATE_MENU
			DrawImage(images[7], 380, 190)

			DrawText "Press SPACE to Start", 300, 270

			If difficulty = DIFFICULTY_NORMAL Then
				DrawText "Difficulty: Normal", 315, 310
			Else
				DrawText "Difficulty: Hard", 325, 310
			End If

			DrawText "Press D to Toggle Difficulty", 280, 340

			If highScore > 0 Then
				DrawText "Today's High Score: " + highScore, 300, 400
			End If

			DrawText "(c) 2026 Bruce A Henderson", 280, 580

			If KeyHit(Key_D) Then
				difficulty = 1 - difficulty
			End If
			If KeyHit(Key_Space) Then
				StartGame()
			End If

		Case STATE_PLAYING
			CheckBulletAsteroidCollisions()
			CheckPlayerAsteroidCollisions()

			UpdateRespawn()
			CheckLevelComplete()

			DrawText "Score: " + score, 10, 10
			DrawText "Lives: " + lives, 10, 30
			DrawText "Level: " + level, 10, 50

			If respawning Then
				DrawRespawnIndicator()
			End If

		Case STATE_GAMEOVER
			DrawText "GAME OVER", 350, 250
			DrawText "Score: " + score, 350, 280

			If score >= highScore Then
				highScore = score
				DrawText "New High Score!", 330, 310
			Else
				DrawText "High Score: " + highScore, 330, 310
			End If

			If gameOverInputDelay > 0 Then
				gameOverInputDelay :- 1
				FlushKeys(True)
			Else
				DrawText "Press SPACE to Return to Menu", 270, 360
	 
				If KeyHit(Key_Space) Then
					FadeOutEntity(gameOverMusicEntity, 0.5)
					gameState = STATE_RETURNING_TO_MENU
				End If
			End If

	End Select
	Flip

Wend



' components

Struct SPosition

	Field x:Float
	Field y:Float

	Method New(x:Float, y:Float)
		Self.x = x; Self.y = y
	End Method

End Struct

Struct SVelocity

	Field x:Float
	Field y:Float

	Method New(x:Float, y:Float)
		Self.x = x; Self.y = y
	End Method

End Struct

Struct SRotation

	Field angle:Float

	Method New(angle:Float)
		Self.angle = angle
	End Method

End Struct

Struct SSprite

	Field imageId:Int
	Field rotationOffset:Float

	Method New(imageId:Int, rotationOffset:Float = 0.0)
		Self.imageId = imageId
		Self.rotationOffset = rotationOffset
	End Method

End Struct

Struct SCollider

	Field radius:Float

	Method New(radius:Float)
		Self.radius = radius
	End Method

End Struct

Struct SLifetime

	Field remaining:Float
	Field total:Float

	Method New(seconds:Float)
		Self.remaining = seconds
		Self.total = seconds
	End Method

End Struct

Struct SAsteroid

	Field size:Int

	Method New(size:Int)
		Self.size = size
	End Method

End Struct

Struct SAngularVelocity

	Field speed:Float

	Method New(speed:Float)
		Self.speed = speed
	End Method

End Struct

Struct SAlpha

	Field value:Float

	Method New(value:Float)
		Self.value = value
	End Method

End Struct

' tags

Struct SPlayer
End Struct

Struct SBullet
End Struct

' audio
Struct SMusic

	Field soundId:Int
	Field channelId:Int
	Field loop:Int

End Struct

Struct SVolume

	Field value:Float

End Struct

Struct SFadeOut

	Field duration:Float
	Field remaining:Float

End Struct

Function StartGame()
	FadeOutEntity(menuMusicEntity, 0.5)

	ClearGame()
	ClearMenu()

	score = 0
	lives = 3
	level = 1
	gameState = STATE_PLAYING

	SpawnPlayer()
	StartLevel()
End Function

Function SpawnPlayer()
	player = world.NewEntity()

	Local p:SPosition = New SPosition(RESPAWN_X, RESPAWN_Y)
	Local v:SVelocity = New SVelocity(0, 0)
	Local r:SRotation = New SRotation(270)
	Local s:SSprite = New SSprite(0, 90)
	Local c:SCollider = New SCollider(16)

	world.SetComponent(player, position, Varptr p)
	world.SetComponent(player, velocity, Varptr v)
	world.SetComponent(player, rotation, Varptr r)
	world.SetComponent(player, sprite, Varptr s)
	world.SetComponent(player, collider, Varptr c)
	world.SetComponent(player, playerTag)
	world.SetComponent(player, gameObjectTag)
End Function

Function SpawnAsteroid:ULong(x:Float, y:Float, size:Int, tagAsGameObject:Int = True)
	Local e:ULong = world.NewEntity()
	Local imageId:Int = 2 + size

	Local ang:Float = Rnd(0, 360)
	Local spd:Float = ASTEROID_DEFAULT_SPEED[size] + Rnd(-0.4, 0.6)
	Local p:SPosition = New SPosition(x, y)
	Local v:SVelocity = New SVelocity(Float(Cos(ang) * spd), Float(Sin(ang) * spd))
	Local s:SSprite = New SSprite(imageId)
	Local c:SCollider = New SCollider(ASTEROID_RADIUS[size])
	Local a:SAsteroid = New SAsteroid(size)
	Local r:SRotation = New SRotation(0)
	Local av:SAngularVelocity = New SAngularVelocity(Float(Rnd(-1.5, 1.5)))
	world.SetComponent(e, position, Varptr p)
	world.SetComponent(e, velocity, Varptr v)
	world.SetComponent(e, sprite, Varptr s)
	world.SetComponent(e, collider, Varptr c)
	world.SetComponent(e, rotation, Varptr r)
	world.SetComponent(e, angularVelocity, Varptr av)
	world.SetComponent(e, asteroid, Varptr a)
	If tagAsGameObject Then
		world.SetComponent(e, gameObjectTag)
	End If

	Return e
End Function

Function SpawnBullet(x:Float, y:Float, angle:Float, shipVX:Float, shipVY:Float)

	' creating a bullet entity from a prefab, which has the sprite, collider, and lifetime components already set up
	Local e:ULong = world.Instantiate(bulletPrefab)

	Local bulletSpeed:Float = 8.0
	Local spawnX:Float = x + Cos(angle) * 12
	Local spawnY:Float = y + Sin(angle) * 12
	Local p:SPosition = New SPosition(spawnX, spawnY)
	Local v:SVelocity = New SVelocity(Float(Cos(angle) * bulletSpeed + shipVX), Float(Sin(angle) * bulletSpeed + shipVY))
	Local r:SRotation = New SRotation(angle)
	world.SetComponent(e, position, Varptr p)
	world.SetComponent(e, velocity, Varptr v)
	world.SetComponent(e, rotation, Varptr r)
	world.SetComponent(e, gameObjectTag)

End Function

Function SpawnSafeLargeAsteroid()

	Local safeX:Float = RESPAWN_X
	Local safeY:Float = RESPAWN_Y
	If world.IsAlive(player) Then
		Local p:SPosition Ptr
		If world.GetComponent(player, position, Varptr p) Then
			safeX = p.x
			safeY = p.y
		End If
	End If
	Local x:Float
	Local y:Float
	Repeat
		x = Rnd(40, 760)
		y = Rnd(40, 560)
	Until DistanceSquared(x, y, safeX, safeY) > PLAYER_SAFE_RADIUS * PLAYER_SAFE_RADIUS
	SpawnAsteroid(x, y, ASTEROID_LARGE)

End Function

Function BreakAsteroid(e:ULong)

	Local p:SPosition Ptr	
	If Not world.GetComponent(e, position, Varptr p) Then
		Return
	End If

	Local a:SAsteroid Ptr
	If Not world.GetComponent(e, asteroid, Varptr a) Then
		Return
	End If

	Local x:Float = p.x
	Local y:Float = p.y
	Local size:Int = a.size
	world.DeleteEntity(e)

	Select size
		Case ASTEROID_LARGE
			score :+ 20
		Case ASTEROID_MEDIUM
			score :+ 50
		Case ASTEROID_SMALL
			score :+ 100
		Case ASTEROID_TINY
			score :+ 200
	End Select

	If size < SmallestAsteroidSize() Then
		SpawnAsteroid(x, y, size + 1)
		SpawnAsteroid(x, y, size + 1)
	End If

End Function

Function StartLevel()

	For Local i:Int = 0 Until level
		SpawnSafeLargeAsteroid()
	Next

End Function

Function ShowGameOver()

	FlushKeys(True)
	gameOverInputDelay = 120
	gameState = STATE_GAMEOVER
	gameOverMusicEntity = StartMusic(1, False)

End Function

Function PlayerInput(it:TEcsIter)

	Local thrusting:Int = False

	Local p:SPosition Ptr
	it.Component(position, 0, Varptr p)

	Local v:SVelocity Ptr
	it.Component(velocity, 1, Varptr v)

	Local r:SRotation Ptr
	it.Component(rotation, 2, Varptr r)

	For Local i:Int = 0 Until it.Count()
		If KeyDown(Key_Left) Then 
			r[i].angle :- 5
		End If

		If KeyDown(Key_Right) Then
			r[i].angle :+ 5
		End If

		If KeyDown(Key_Up) Then
			thrusting = True
			v[i].x :+ Cos(r[i].angle) * 0.25
			v[i].y :+ Sin(r[i].angle) * 0.25

			SpawnThrustParticles(p[i].x, p[i].y, r[i].angle, v[i].x, v[i].y)
		End If

		v[i].x :* 0.99
		v[i].y :* 0.99

		If KeyHit(Key_Space) Then
			If difficulty = DIFFICULTY_HARD Then
				If BulletCount() < 5 Then
					SpawnBullet(p[i].x, p[i].y, r[i].angle, v[i].x, v[i].y)
					PlaySound(sounds[2])
				End If
			Else
				SpawnBullet(p[i].x, p[i].y, r[i].angle, v[i].x, v[i].y)
				PlaySound(sounds[2])
			End If
		End If
	Next

	If thrusting Then

	If Not thrustChannel Or Not ChannelPlaying(thrustChannel) Then
			thrustChannel = PlaySound(sounds[5])
			SetChannelVolume(thrustChannel, 0.5)
		End If
	Else
		If thrustChannel Then
			StopChannel(thrustChannel)
			thrustChannel = Null
		End If
	End If

End Function

Function Move(it:TEcsIter)

	Local p:SPosition Ptr
	it.Component(position, 0, Varptr p)

	Local v:SVelocity Ptr
	it.Component(velocity, 1, Varptr v)

	For Local i:Int = 0 Until it.Count()
		p[i].x :+ v[i].x
		p[i].y :+ v[i].y
	Next

End Function

Function WrapScreen(it:TEcsIter)

	Local p:SPosition Ptr
	it.Component(position, 0, Varptr p)

	For Local i:Int = 0 Until it.Count()
		If p[i].x < -20 Then
			p[i].x :+ 840
		End If

		If p[i].x >= 820 Then
			p[i].x :- 840
		End If

		If p[i].y < -20 Then
			p[i].y :+ 640
		End If

		If p[i].y >= 620 Then
			p[i].y :- 640
		End If
	Next

End Function

Function LifetimeSystem(it:TEcsIter)

	Local l:SLifetime Ptr
	it.Component(lifetime, 0, Varptr l)

	For Local i:Int = 0 Until it.Count()
		l[i].remaining :- 1.0 / 60.0
		If l[i].remaining <= 0 Then
			world.QueueDelete(it.Entity(i))
		End If
	Next

End Function

Function Render(it:TEcsIter)

	Local p:SPosition Ptr
	it.Component(position, 0, Varptr p)

	Local s:SSprite Ptr
	it.Component(sprite, 1, Varptr s)

	Local r:SRotation Ptr
	it.Component(rotation, 2, Varptr r)

	For Local i:Int = 0 Until it.Count()
		SetRotation(r[i].angle + s[i].rotationOffset)
		DrawImage(images[s[i].imageId], p[i].x, p[i].y)
		SetRotation(0)
	Next
End Function

Function DistanceSquared:Float(x1:Float, y1:Float, x2:Float, y2:Float)
	Local dx:Float = x1 - x2
	Local dy:Float = y1 - y2
	Return dx * dx + dy * dy
End Function

Function CheckLevelComplete()

	Local ait:TEcsQueryIter = asteroidQuery.Iter()
	While ait.Advance()
		If ait.Count() > 0 Then
			Return
		End If
	Wend
	level :+ 1
	StartLevel()

End Function

Function CheckBulletAsteroidCollisions()
	Local bit:TEcsQueryIter = bulletQuery.Iter()

	While bit.Advance()
		Local bp:SPosition Ptr
		bit.Component(position, 0, Varptr bp)

		Local bv:SVelocity Ptr
		bit.Component(velocity, 2, Varptr bv)

		Local bc:SCollider Ptr
		bit.Component(collider, 1, Varptr bc)

		For Local bi:Int = 0 Until bit.Count()
			Local bulletEntity:ULong = bit.Entity(bi)

			Local ait:TEcsQueryIter = asteroidQuery.Iter()

			While ait.Advance()
				Local ap:SPosition Ptr
				ait.Component(position, 0, Varptr ap)

				Local ac:SCollider Ptr
				ait.Component(collider, 1, Varptr ac)

				For Local ai:Int = 0 Until ait.Count()
					Local asteroidEntity:ULong = ait.Entity(ai)

					Local r:Float = bc[bi].radius + ac[ai].radius

					If DistanceSquared(bp[bi].x, bp[bi].y, ap[ai].x, ap[ai].y) <= r * r Then

						PlaySound(sounds[4])

						SpawnSparks(ap[ai].x, ap[ai].y, bv[bi].x, bv[bi].y)
						world.DeleteEntity(bulletEntity)
						BreakAsteroid(asteroidEntity)
						Exit
					End If
				Next
			Wend
		Next
	Wend
End Function

Function CheckPlayerAsteroidCollisions()
	If Not world.IsAlive(player) Then Return

	Local pp:SPosition Ptr
	If Not world.GetComponent(player, position, Varptr pp) Then
		Return
	End If

	Local pc:SCollider Ptr
	If Not world.GetComponent(player, collider, Varptr pc) Then
		Return
	End If

	Local ait:TEcsQueryIter = asteroidQuery.Iter()

	While ait.Advance()
		Local ap:SPosition Ptr
		ait.Component(position, 0, Varptr ap)

		Local ac:SCollider Ptr
		ait.Component(collider, 1, Varptr ac)

		For Local ai:Int = 0 Until ait.Count()
			Local r:Float = pc.radius + ac[ai].radius

			If DistanceSquared(pp.x, pp.y, ap[ai].x, ap[ai].y) <= r * r Then

				PlaySound(sounds[3])

				Local pv:SVelocity Ptr
				If world.GetComponent(player, velocity, Varptr pv) Then
					SpawnShipExplosion(pp.x, pp.y, pv.x, pv.y)
				Else
					SpawnShipExplosion(pp.x, pp.y, 0, 0)
				End If

				If thrustChannel Then
					StopChannel(thrustChannel)
					thrustChannel = Null
				End If

				lives :- 1
				world.DeleteEntity(player)

				If lives <= 0 Then
					ShowGameOver()
				Else
					respawning = True
					respawnTimer = 60
				End If

				Return
			End If
		Next
	Wend
End Function

Function ClearGame()

	world.DeferBegin() ' Defer deletions until we've finished iterating to avoid issues with deleting entities while iterating over them

	Local it:TEcsQueryIter = gameObjectQuery.Iter()
	While it.Advance()
		For Local i:Int = 0 Until it.Count()
			world.DeleteEntity(it.Entity(i))
		Next
	Wend

	world.DeferEnd()

	player = 0

End Function

Function SmallestAsteroidSize:Int()

	If difficulty = DIFFICULTY_HARD Then
		Return ASTEROID_TINY
	End If
	Return ASTEROID_SMALL

End Function

Function Rotate(it:TEcsIter)

	Local r:SRotation Ptr
	it.Component(rotation, 0, Varptr r)

	Local av:SAngularVelocity Ptr
	it.Component(angularVelocity, 1, Varptr av)

	For Local i:Int = 0 Until it.Count()
		r[i].angle :+ av[i].speed
	Next

End Function

Function Fade(it:TEcsIter)

	Local l:SLifetime Ptr
	it.Component(lifetime, 0, Varptr l)

	Local a:SAlpha Ptr
	it.Component(alpha, 1, Varptr a)

	For Local i:Int = 0 Until it.Count()
		If l[i].total > 0 Then
			a[i].value = l[i].remaining / l[i].total
		Else
			a[i].value = 0
		End If
	Next

End Function

Function RenderAlpha(it:TEcsIter)

	Local p:SPosition Ptr
	it.Component(position, 0, Varptr p)

	Local s:SSprite Ptr
	it.Component(sprite, 1, Varptr s)

	Local a:SAlpha Ptr
	it.Component(alpha, 2, Varptr a)

	For Local i:Int = 0 Until it.Count()
		SetAlpha(a[i].value)
		DrawImage(images[s[i].imageId], p[i].x, p[i].y)
		SetAlpha(1.0)
	Next

End Function

Function SpawnParticle(x:Float, y:Float, vx:Float, vy:Float, minLife:Float = 0.25, maxLife:Float = 0.55)

	Local e:ULong = world.NewEntity()
	Local p:SPosition = New SPosition(x, y)
	Local v:SVelocity = New SVelocity(vx, vy)
	Local s:SSprite = New SSprite(6)
	Local l:SLifetime = New SLifetime(Float(Rnd(minLife, maxLife)))
	Local a:SAlpha = New SAlpha(1.0)

	world.SetComponent(e, position, Varptr p)
	world.SetComponent(e, velocity, Varptr v)
	world.SetComponent(e, sprite, Varptr s)
	world.SetComponent(e, lifetime, Varptr l)
	world.SetComponent(e, alpha, Varptr a)
	world.SetComponent(e, particleTag)
	world.SetComponent(e, gameObjectTag)

End Function

Function SpawnSparks(x:Float, y:Float, hitVX:Float, hitVY:Float)

	For Local i:Int = 0 Until 18
		Local spread:Float = -35 + i * 4
		Local speed:Float = Rnd(1, 2)
		Local baseAngle:Float = ATan2(hitVY, hitVX)
		Local ang:Float = baseAngle + spread
		Local vx:Float = Cos(ang) * speed + hitVX * 0.1
		Local vy:Float = Sin(ang) * speed + hitVY * 0.1
		SpawnParticle(Float(x + Rnd(-3, 3)), Float(y + Rnd(-3, 3)), vx, vy)
	Next

End Function

Function PlaySoundId:Int(soundId:Int, vol:Float = 1.0)

	Local ch:TChannel = PlaySound(sounds[soundId])
	Local id:Int = nextChannelId
	nextChannelId :+ 1
	SetChannelVolume(ch, vol)
	channels.Put(id, ch)
	Return id

End Function

Function StopChannelId(channelId:Int)

	Local ch:TChannel
	If channels.TryGetValue(channelId, ch) Then
		StopChannel(ch)
		channels.Remove(channelId)
	End If

End Function

Function ChannelPlayingId:Int(channelId:Int)

	Local ch:TChannel
	If channels.TryGetValue(channelId, ch) Then
		Return ch.Playing()
	End If
	Return False

End Function

Function SetChannelVolumeId(channelId:Int, vol:Float)

	Local ch:TChannel
	If channels.TryGetValue(channelId, ch) Then
		SetChannelVolume(ch, vol)
	End If

End Function

Function StartMusic:ULong(soundId:Int, loop:Int)

	Local e:ULong = world.NewEntity()
	Local m:SMusic
	m.soundId = soundId
	m.channelId = 0
	m.loop = loop
	Local v:SVolume
	v.value = 1.0
	world.SetComponent(e, music, Varptr m)
	world.SetComponent(e, volume, Varptr v)
	Return e

End Function

Function FadeOutEntity(entity:ULong, duration:Float)

	If Not world.IsAlive(entity) Then Return
	Local f:SFadeOut
	f.duration = duration
	f.remaining = duration
	world.SetComponent(entity, fadeOut, Varptr f)

End Function

Function ShowMenu()
	ClearGame()
	ClearMenu()

	gameState = STATE_MENU
	SpawnMenuAsteroids()
	menuMusicEntity = StartMusic(0, True)
	gameOverMusicEntity = 0

End Function

Function MusicUpdate(it:TEcsIter)

	Local m:SMusic Ptr
	it.Component(music, 0, Varptr m)

	Local v:SVolume Ptr
	it.Component(volume, 1, Varptr v)

	For Local i:Int = 0 Until it.Count()
		Local e:ULong = it.Entity(i)
		If m[i].channelId = 0 Then
			m[i].channelId = PlaySoundId(m[i].soundId, v[i].value)
		End If

		Local f:SFadeOut Ptr
		If world.GetComponent(e, fadeOut, Varptr f) Then
			f.remaining :- 1.0 / 60.0
			If f.duration > 0 Then
				v[i].value = Max(0.0, f.remaining / f.duration)
			Else
				v[i].value = 0.0
			End If
			SetChannelVolumeId(m[i].channelId, v[i].value)
			If f.remaining <= 0 Then
				StopChannelId(m[i].channelId)
				m[i].channelId = 0
				If gameState = STATE_RETURNING_TO_MENU And e = gameOverMusicEntity Then
					ShowMenu()
				Else
					world.QueueDelete(e)
				End If
			End If
			Continue
		End If
		If m[i].channelId <> 0 And Not ChannelPlayingId(m[i].channelId) Then
			channels.Remove(m[i].channelId)
			m[i].channelId = 0
			If m[i].loop Then
				m[i].channelId = PlaySoundId(m[i].soundId, v[i].value)
			Else
				world.SetComponent(e, finishedTag)

				If gameState = STATE_GAMEOVER And e = gameOverMusicEntity Then
					world.QueueDelete(e)
					gameOverMusicEntity = 0
					ShowMenu()
				End If
			End If
		End If
	Next

End Function

Function OnMusicFinished(it:TEcsIter)

	For Local i:Int = 0 Until it.Count()
		world.QueueDelete(it.Entity(i))
	Next

End Function

Function FlushFinishedMusicQueue()

	While Not finishedMusicQueue.IsEmpty()
		Local e:ULong = finishedMusicQueue.Dequeue()
		If world.IsAlive(e) Then
			world.SetComponent(e, finishedTag)
		End If
	Wend

End Function

Function SpawnMenuAsteroids()

	For Local i:Int = 0 Until 6
		Local e:ULong = SpawnAsteroid(Float(Rnd(40, 760)), Float(Rnd(40, 560)), ASTEROID_LARGE, False)
		world.SetComponent(e, menuObjectTag)
	Next

End Function

Function ClearMenu()

	world.DeferBegin()
	Local it:TEcsQueryIter = menuObjectQuery.Iter()
	While it.Advance()
		For Local i:Int = 0 Until it.Count()
			world.DeleteEntity(it.Entity(i))
		Next
	Wend
	world.DeferEnd()

End Function

Function SpawnThrustParticles(x:Float, y:Float, angle:Float, shipVX:Float, shipVY:Float)

	' exhaust comes from behind the ship
	Local backAngle:Float = angle + 180
	Local exhaustX:Float = x + Cos(backAngle) * 10
	Local exhaustY:Float = y + Sin(backAngle) * 10
	For Local i:Int = 0 Until 2
		Local spread:Float = Rnd(-18, 18)
		Local speed:Float = Rnd(1.0, 2.8)
		Local a:Float = backAngle + spread
		Local vx:Float = Cos(a) * speed + shipVX * 0.2
		Local vy:Float = Sin(a) * speed + shipVY * 0.2
		SpawnParticle(Float(exhaustX + Rnd(-2, 2)), Float(exhaustY + Rnd(-2, 2)), vx, vy)
	Next

End Function

Function UpdateRespawn()

	If Not respawning Then Return
	If world.IsAlive(player) Then
		respawning = False
		Return
	End If
	If respawnTimer > 0 Then
		respawnTimer :- 1
		Return
	End If
	If RespawnAreaClear() Then
		SpawnPlayer()
		respawning = False
	Else
		respawnTimer = 15
	End If

End Function

Function RespawnAreaClear:Int()

	Local ait:TEcsQueryIter = asteroidQuery.Iter()
	While ait.Advance()
		Local p:SPosition Ptr
		ait.Component(position, 0, Varptr p)
		Local c:SCollider Ptr
		ait.Component(collider, 1, Varptr c)
		For Local i:Int = 0 Until ait.Count()
			Local r:Float = PLAYER_SAFE_RADIUS + c[i].radius
			If DistanceSquared(RESPAWN_X, RESPAWN_Y, p[i].x, p[i].y) <= r * r Then
				Return False
			End If
		Next
	Wend
	Return True

End Function

Function DrawRespawnIndicator()

	Local count:Int = 24
	Local radius:Float = 28
	Local t:Float = Millisecs() * 0.12
	For Local i:Int = 0 Until count
		Local a:Float = (Float(i) / Float(count)) * 360.0 + t
		Local pulse:Float = (Sin(t * 2.0 + i * 20.0) + 1.0) * 0.5
		Local x:Float = RESPAWN_X + Cos(a) * radius
		Local y:Float = RESPAWN_Y + Sin(a) * radius
		SetAlpha(0.25 + pulse * 0.75)
		DrawImage(images[6], x, y)
	Next
	SetAlpha(1.0)

End Function

Function BulletCount:Int()

	Local count:Int
	Local it:TEcsQueryIter = bulletQuery.Iter()
	While it.Advance()
		count :+ it.Count()
	Wend
	Return count

End Function

Function SpawnShipExplosion(x:Float, y:Float, vx:Float, vy:Float)

	For Local i:Int = 0 Until 64
		Local ang:Float = Rnd(0, 360)
		Local speed:Float
		Local minLife:Float = 0.5
		Local maxLife:Float = 1.2
		Select Rand(0, 9)
			Case 0
				speed = Rnd(3.5, 5.0)   ' few fast sparks
				minLife = 0.25
				maxLife = 0.55
			Case 1, 2, 3
				speed = Rnd(1.5, 3.0)   ' some medium
				minLife = 0.3
				maxLife = 0.7
			Default
				speed = Rnd(0.3, 1.5)   ' mostly slow
		End Select
		Local px:Float = x + Rnd(-6, 6)
		Local py:Float = y + Rnd(-6, 6)
		Local pvx:Float = Cos(ang) * speed + vx * 0.2
		Local pvy:Float = Sin(ang) * speed + vy * 0.2
		SpawnParticle(px, py, pvx, pvy, minLife, maxLife)
	Next

End Function
