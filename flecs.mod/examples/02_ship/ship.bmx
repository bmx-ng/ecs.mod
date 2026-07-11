SuperStrict

Framework SDL.sdlrendermax2d
Import image.png
Import Ecs.Flecs
Import brl.random

Graphics 800, 600

Global images:TImage[] = New TImage[2]

images[0] = LoadImage("ship.png")
SetImageHandle(images[0], images[0].Width / 2, images[0].Height / 2)
images[1] = LoadImage("bullet.png")
SetImageHandle(images[1], images[1].Width / 2, images[1].Height / 2)

Global world:TEcsWorld = TEcsWorld.Create()

Global position:SEcsComponent = world.RegisterComponent("Position", SizeOf(SPosition), AlignOf(SPosition))
Global velocity:SEcsComponent = world.RegisterComponent("Velocity", SizeOf(SVelocity), AlignOf(SVelocity))
Global sprite:SEcsComponent = world.RegisterComponent("Sprite", SizeOf(SSprite), AlignOf(SSprite))
Global lifetime:SEcsComponent = world.RegisterComponent("Lifetime", SizeOf(SLifetime), AlignOf(SLifetime))
Global playerTag:SEcsComponent = world.RegisterComponent("Player", 0, 0)
Global bulletTag:SEcsComponent = world.RegisterComponent("Bullet", 0, 0)

Global player:ULong = world.NewEntity()

Local pp:SPosition = New SPosition(400, 520)
Local pv:SVelocity = New SVelocity(0, 0)
Local ps:SSprite = New SSprite(0)

world.SetComponent(player, position, Varptr pp)
world.SetComponent(player, velocity, Varptr pv)
world.SetComponent(player, sprite, Varptr ps)
world.SetComponent(player, playerTag)

world.RegisterSystem("PlayerInput", EcsOnUpdate, [position.id, velocity.id, playerTag.id], PlayerInput)
world.RegisterSystem("Move", EcsOnUpdate, [position.id, velocity.id], Move)
world.RegisterSystem("Lifetime", EcsOnUpdate, [lifetime.id], LifetimeSystem)
world.RegisterSystem("Render", EcsOnUpdate, [position.id, sprite.id], Render)

While Not KeyDown(Key_Escape)
	Cls

	world.Progress(1.0 / 60.0)

	Flip
Wend

Struct SPosition
	Field x:Float
	Field y:Float

	Method New(x:Float, y:Float)
		Self.x = x
		Self.y = y
	End Method
End Struct

Struct SVelocity
	Field x:Float
	Field y:Float

	Method New(x:Float, y:Float)
		Self.x = x
		Self.y = y
	End Method
End Struct

Struct SSprite
	Field imageId:Int

	Method New(imageId:Int)
		Self.imageId = imageId
	End Method
End Struct

Struct SLifetime
	Field remaining:Float

	Method New(remaining:Float)
		Self.remaining = remaining
	End Method
End Struct

Struct SPlayer
End Struct

Struct SBullet
End Struct

Function PlayerInput(it:TEcsIter)
	Local p:SPosition Ptr
	it.Component(position, 0, Varptr p)

	Local v:SVelocity Ptr
	it.Component(velocity, 1, Varptr v)

	For Local i:Int = 0 Until it.Count()
		v[i].x = 0
		v[i].y = 0

		If KeyDown(Key_Left) Then v[i].x = -5
		If KeyDown(Key_Right) Then v[i].x = 5
		If KeyDown(Key_Up) Then v[i].y = -5
		If KeyDown(Key_Down) Then v[i].y = 5

		If KeyHit(Key_Space) Then
			SpawnBullet(p[i].x, p[i].y - 24)
		End If
	Next
End Function

Function SpawnBullet(x:Float, y:Float)
	Local e:ULong = world.NewEntity()

	Local p:SPosition = New SPosition(x, y)
	Local v:SVelocity = New SVelocity(0, -10)
	Local s:SSprite = New SSprite(1)
	Local l:SLifetime = New SLifetime(1)

	world.SetComponent(e, position, Varptr p)
	world.SetComponent(e, velocity, Varptr v)
	world.SetComponent(e, sprite, Varptr s)
	world.SetComponent(e, lifetime, Varptr l)
	world.SetComponent(e, bulletTag)
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

Function LifetimeSystem(it:TEcsIter)

	Local l:SLifetime Ptr
	it.Component(lifetime, 0, Varptr l)

	For Local i:Int = 0 Until it.Count()
		l[i].remaining :- 1.0 / 60.0
		
		If l[i].remaining <= 0 Then
			world.DeleteEntity(it.Entity(i))
		End If
	Next

End Function

Function Render(it:TEcsIter)
	Local p:SPosition Ptr
	it.Component(position, 0, Varptr p)

	Local s:SSprite Ptr
	it.Component(sprite, 1, Varptr s)

	For Local i:Int = 0 Until it.Count()
		DrawImage(images[s[i].imageId], p[i].x, p[i].y)
	Next
End Function
