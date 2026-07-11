SuperStrict

Framework SDL.sdlrendermax2d
Import image.png
Import Ecs.Flecs
Import brl.random

Graphics 800, 600

Global images:TImage[] = New TImage[1]

images[0] = LoadImage("crate.png")
SetImageHandle(images[0], images[0].Width / 2, images[0].Height / 2)

Global world:TEcsWorld = TEcsWorld.Create()

Global position:SEcsComponent = world.RegisterComponent("Position", SizeOf(SPosition), AlignOf(SPosition))
Global velocity:SEcsComponent = world.RegisterComponent("Velocity", SizeOf(SVelocity), AlignOf(SVelocity))
Global sprite:SEcsComponent   = world.RegisterComponent("Sprite",   SizeOf(SSprite),   AlignOf(SSprite))

world.RegisterSystem("Move", EcsOnUpdate, [position.id, velocity.id], Move)
world.RegisterSystem("Bounce", EcsOnUpdate, [position.id, velocity.id], Bounce)
world.RegisterSystem("Render", EcsOnUpdate, [position.id, sprite.id], Render)

For Local i:Int = 0 Until 100
	Local e:ULong = world.NewEntity()

	Local p:SPosition = New SPosition(Float(Rnd(32, 768)), Float(Rnd(32, 568)))
	Local v:SVelocity = New SVelocity(Float(Rnd(-4, 4)), Float(Rnd(-4, 4)))
	Local s:SSprite = New SSprite(0)

	world.SetComponent(e, position, Varptr p)
	world.SetComponent(e, velocity, Varptr v)
	world.SetComponent(e, sprite, Varptr s)
Next

While Not KeyDown(Key_Escape)
	Cls

	world.Progress(0.0)

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

Function Bounce(it:TEcsIter)
	Local p:SPosition Ptr
	it.Component(position, 0, Varptr p)

	Local v:SVelocity Ptr
	it.Component(velocity, 1, Varptr v)

	For Local i:Int = 0 Until it.Count()
		If p[i].x < 16 Or p[i].x > 784 Then
			v[i].x = -v[i].x
		End If

		If p[i].y < 16 Or p[i].y > 584 Then
			v[i].y = -v[i].y
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
