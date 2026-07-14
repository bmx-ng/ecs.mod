' Copyright (c) 2026 Bruce A Henderson
' 
' Permission is hereby granted, free of charge, to any person obtaining a copy
' of this software and associated documentation files (the "Software"), to deal
' in the Software without restriction, including without limitation the rights
' to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
' copies of the Software, and to permit persons to whom the Software is
' furnished to do so, subject to the following conditions:
' 
' The above copyright notice and this permission notice shall be included in
' all copies or substantial portions of the Software.
' 
' THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
' IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
' FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
' AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
' LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
' OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
' THE SOFTWARE.
' 
SuperStrict

Rem
bbdoc: A flecs based Entity Component System (ECS)
End Rem
Module Ecs.Flecs

ModuleInfo "Version: 1.00"
ModuleInfo "License: MIT"
ModuleInfo "Copyright: flecs - 2025 Sander Mertens"
ModuleInfo "Copyright: BlitzMax wrapper - 2026 Bruce A Henderson"

ModuleInfo "History: 1.00 Initial Release"

ModuleInfo "CC_OPTS: -std=c99"

?Win32
Import "-limagehlp"
Import "-ldbghelp"
?

Import Collections.HashMap
Import Collections.Queue
Import BRL.Reflection

Import "common.bmx"

Rem
bbdoc: The world is the container for all ECS data.
about: It stores the entities and their components, does queries and runs systems.
Typically there is only a single world, but there is no limit on the number of worlds an application can create.
End Rem
Type TEcsWorld

	Field worldPtr:Byte Ptr

	Field systems:THashMap<String, TEcsSystem> = New THashMap<String, TEcsSystem>
	Field observers:THashMap<String, TEcsObserver> = New THashMap<String, TEcsObserver>

	Field deleteQueue:TQueue<ULong> = New TQueue<ULong>

	Rem
	bbdoc: Creates a new world instance.
	End Rem
	Function Create:TEcsWorld()
		Local this:TEcsWorld = New TEcsWorld
		this.worldPtr = ecs_init()
		Return this
	End Function

	Rem
	bbdoc: Queues an entity for deletion.
	about: The entity will be deleted when #FlushCommands is called.
	End Rem
	Method QueueDelete(entity:ULong)
		deleteQueue.Enqueue(entity)
	End Method

	Method FlushCommands()
		While Not deleteQueue.IsEmpty()
			Local e:ULong = deleteQueue.Dequeue()
			If IsAlive(e) Then
				DeleteEntity(e)
			End If
		Wend
	End Method

	Rem
	bbdoc: Updates the world, running all systems and processing any deferred commands.
	about: Similar to #Progress, but also flushes any queued commands after running the systems.
	The @deltaTime parameter specifies the amount of time to advance the world by. If @deltaTime is 0.0, the world will use the default time step.
	End Rem
	Method Update:Int(deltaTime:Float = 0.0)
		Local result:Int = Progress(deltaTime)
		FlushCommands()
		Return result
	End Method

	Rem
	bbdoc: Registers a new component type with the world.
	about: A component defines a type of data that can be associated with an entity.
	Each component type has a unique ID, which is used to identify it in queries and when adding/removing components from entities.
	End Rem
	Method RegisterComponent:SEcsComponent(name:String, size:Size_T, alignment:Size_T)
		Local component:SEcsComponent
		component.id = bmx_ecs_register_component(worldPtr, name, size, alignment)
		component.size = size
		Return component
	End Method

	Rem
	bbdoc: Registers a new system with the world.
	about: A system defines a set of operations that are performed on entities with specific components.
	End Rem
	Method RegisterSystem:TEcsSystem(name:String, phase:ULong, componentIds:ULong[], callback(it:TEcsIter))
		Local system:TEcsSystem = New TEcsSystem
		system.callback = callback
		system.id = bmx_ecs_register_system(worldPtr, name, phase, componentIds, componentIds.Length, system)
		systems.Put(name, system)
		return system
	End Method

	Method RegisterSystem:TEcsSystem(name:String, phase:ULong, componentIds:ULong Ptr, componentCount:Int, callback(it:TEcsIter))
		Local system:TEcsSystem = New TEcsSystem
		system.callback = callback
		system.id = bmx_ecs_register_system(worldPtr, name, phase, componentIds, componentCount, system)
		systems.Put(name, system)
		return system
	End Method

	Rem
	bbdoc: Registers a new system with the world using an array of terms (#SEcsTerm).
	about: A system defines a set of operations that are performed on entities with specific components.
	End Rem
	Method RegisterSystem:TEcsSystem(name:String, phase:ULong, terms:SEcsTerm[], callback(it:TEcsIter))
		Local system:TEcsSystem = New TEcsSystem
		system.callback = callback
		system.id = bmx_ecs_register_system_terms(worldPtr, name, phase, terms, terms.Length, system)
		systems.Put(name, system)
		return system
	End Method

	Rem
	bbdoc: Registers a new system with the world using a pointer to an array of terms (#SEcsTerm) and a count of the number of terms.
	about: A system defines a set of operations that are performed on entities with specific components.
	End Rem
	Method RegisterSystem:TEcsSystem(name:String, phase:ULong, terms:SEcsTerm Ptr, termCount:Int, callback(it:TEcsIter))
		Local system:TEcsSystem = New TEcsSystem
		system.callback = callback
		system.id = bmx_ecs_register_system_terms(worldPtr, name, phase, terms, termCount, system)
		systems.Put(name, system)
		return system
	End Method

	Rem
	bbdoc: Registers a new system with the world using an array of components (#SEcsComponent).
	about: A system defines a set of operations that are performed on entities with specific components.
	End Rem
	Method RegisterSystem:TEcsSystem(name:String, phase:ULong, components:SEcsComponent[], callback(it:TEcsIter))
		Local componentIds:ULong Ptr = StackAlloc(components.Length * SizeOf(0:ULong))

		For Local i:Int = 0 Until components.Length
			componentIds[i] = components[i].id
		Next

		Return RegisterSystem(name, phase, componentIds, components.Length, callback)
	End Method

	Rem
	bbdoc: Registers a new observer with the world.
	about: An observer is a callback that is invoked when a specific event occurs on an entity with specific components.
	End Rem
	Method RegisterObserver:TEcsObserver(name:String, event:ULong, componentIds:ULong[], callback(iter:TEcsIter))
		Local observer:TEcsObserver = New TEcsObserver
		observer.worldPtr = worldPtr
		observer.callback = callback
		observer.id = bmx_ecs_register_observer(worldPtr, name, event, componentIds, componentIds.Length, observer)
		observers.Put(name, observer)
		Return observer
	End Method

	Rem
	bbdoc: Registers a new observer with the world using a pointer to an array of component IDs and a count of the number of components.
	about: An observer is a callback that is invoked when a specific event occurs on an entity with specific components.
	End Rem
	Method RegisterObserver:TEcsObserver(name:String, event:ULong, componentIds:ULong Ptr, count:Int, callback(iter:TEcsIter))
		Local observer:TEcsObserver = New TEcsObserver
		observer.worldPtr = worldPtr
		observer.callback = callback
		observer.id = bmx_ecs_register_observer(worldPtr, name, event, componentIds, count, observer)
		observers.Put(name, observer)
		Return observer
	End Method

	Rem
	bbdoc: Registers metadata for a struct type with the world.
	about: This allows the ECS to understand the layout of the struct and its fields, enabling features like serialization, reflection, and more.
	End Rem
	Method RegisterStructMeta(name:String, componentId:ULong)
		Local ty:TTypeId = TTypeId.ForName(name)
		If Not ty Then
			Throw "Type '" + name + "' not found for RegisterStructMeta"
		End If

		If Not ty.IsStruct() Then
			Throw "Type '" + name + "' is not a struct type for RegisterStructMeta"
		End If

		Local fields:SEcsMetaField[0]

		For Local fld:TField = EachIn ty.Fields()

			Local structId:ULong = 0
			Local kind:EEscPrimitiveKind = EEscPrimitiveKind.None

			Select fld.TypeId()
				Case ByteTypeId
					kind = EEscPrimitiveKind.EcsU8
				Case ShortTypeId
					kind = EEscPrimitiveKind.EcsU16
				Case IntTypeId
					kind = EEscPrimitiveKind.EcsI32
				Case UIntTypeId
					kind = EEscPrimitiveKind.EcsU32
				Case LongTypeId
					kind = EEscPrimitiveKind.EcsI64
				Case ULongTypeId
					kind = EEscPrimitiveKind.EcsU64
				Case SizetTypeId
					kind = EEscPrimitiveKind.EcsUPtr
				Case FloatTypeId
					kind = EEscPrimitiveKind.EcsF32
				Case DoubleTypeId
					kind = EEscPrimitiveKind.EcsF64
				Case LongIntTypeId
					kind = EEscPrimitiveKind.EcsIPtr
				Case ULongIntTypeId
					kind = EEscPrimitiveKind.EcsUPtr
			End Select

			If fld.typeId().IsStruct() Then
				' TODO: Handle nested structs.
			End If

			If kind <> EEscPrimitiveKind.None Then
				fields :+ [New SEcsMetaField(fld.Name(), kind, fld.GetOffset())]
			End If
		Next

		If fields.Length = 0 Then
			Return
		End If

		' Register the struct meta with Flecs
		bmx_ecs_register_struct_meta(worldPtr, componentId, fields, fields.Length)
	End Method

	Rem
	bbdoc: Creates a new entity in the world, optionally with a specified name.
	End Rem
	Method NewEntity:ULong(name:String = Null)
		Return bmx_ecs_new_entity(worldPtr, name)
	End Method

	Rem
	bbdoc: Sets a component on an entity, optionally with data.
	about: If data is #Null, the component is added without setting any data (useful for tag components).
	End Rem
	Method SetComponent(entityId:ULong, component:SEcsComponent, data:Byte Ptr)
		If Not data Then
			' If data is Null, we want to add the component without setting any data. This is useful for tag components that don't have any associated data.
			bmx_ecs_add_component(worldPtr, entityId, component.id)
		Else
			bmx_ecs_set_component(worldPtr, entityId, component.id, component.size, data)
		End If
	End Method

	Rem
	bbdoc: Adds a component to an entity.
	End Rem
	Method SetComponent(entityId:ULong, component:SEcsComponent)
		bmx_ecs_add_component(worldPtr, entityId, component.id)
	End Method

	Rem
	bbdoc: Adds a component to an entity.
	End Rem
	Method AddComponent(entityId:ULong, component:SEcsComponent)
		bmx_ecs_add_component(worldPtr, entityId, component.id)
	End Method

	Rem
	bbdoc: Sets a singleton component in the world.
	End Rem
	Method SetSingleton(component:SEcsComponent, data:Byte Ptr)
		bmx_ecs_set_component(worldPtr, component.id, component.id, component.size, data)
	End Method

	Rem
	bbdoc: Steps the world forward in time, running all systems and processing any deferred commands.
	about: The @deltaTime parameter specifies the amount of time to advance the world by. If @deltaTime is 0.0, the world will use the default time step.

	See #Update, which also flushes any queued commands after running the systems.
	End Rem
	Method Progress:Int(deltaTime:Float = 0.0)
		Return bmx_ecs_progress(worldPtr, deltaTime)
	End Method

	Rem
	bbdoc: Runs a specific system in the world, optionally with a specified delta time.
	about: The @deltaTime parameter specifies the amount of time to advance the world by. If @deltaTime is 0.0, the world will use the default time step.
	End Rem
	Method Run(system:TEcsSystem, deltaTime:Float = 0.0)
		bmx_ecs_run(worldPtr, system.id, deltaTime)
	End Method

	Rem
	bbdoc:
	returns: #True if the entity is alive, #False if it has been deleted.
	End Rem
	Method GetComponent:Int(entity:ULong, component:SEcsComponent, data:Byte Ptr Ptr)
    	Return bmx_ecs_get_component(worldPtr, entity, component.id, data)
	End Method

	Rem
	bbdoc: Determines if an entity has a specific component.
	returns: #True if the entity has the component, #False otherwise.
	End Rem
	Method HasComponent:Int(entity:ULong, component:SEcsComponent)
		Return bmx_ecs_has_component(worldPtr, entity, component.id)
	End Method

	Rem
	bbdoc: Determines if an entity has a specific component by its ID.
	returns: #True if the entity has the component, #False otherwise.
	End Rem
	Method HasComponent:Int(entity:ULong, componentId:ULong)
		Return bmx_ecs_has_component(worldPtr, entity, componentId)
	End Method

	Rem
	bbdoc: Removes a component from an entity.
	End Rem
	Method RemoveComponent(entity:ULong, component:SEcsComponent)
		bmx_ecs_remove_component(worldPtr, entity, component.id)
	End Method

	Rem
	bbdoc: Removes a component from an entity by its ID.
	End Rem
	Method RemoveComponent(entity:ULong, componentId:ULong)
		bmx_ecs_remove_component(worldPtr, entity, componentId)
	End Method

	Rem
	bbdoc: Retrieves a singleton component from the world.
	returns: #True if the singleton component exists, #False otherwise.
	End Rem
	Method GetSingleton:Int(component:SEcsComponent, data:Byte Ptr Ptr)
		Return bmx_ecs_get_component(worldPtr, component.id, component.id, data)
	End Method

	Rem
	bbdoc: Determines if a singleton component exists in the world.
	returns: #True if the singleton component exists, #False otherwise.
	End Rem
	Method HasSingleton:Int(component:SEcsComponent)
		Return bmx_ecs_has_component(worldPtr, component.id, component.id)
	End Method

	Rem
	bbdoc: Removes a singleton component from the world.
	End Rem
	Method RemoveSingleton(component:SEcsComponent)
		bmx_ecs_remove_component(worldPtr, component.id, component.id)
	End Method

	Rem
	bbdoc: Removes a singleton component from the world by its ID.
	End Rem
	Method RemoveSingleton(componentId:ULong)
		bmx_ecs_remove_component(worldPtr, componentId, componentId)
	End Method

	Rem
	bbdoc: Marks a singleton component as modified.
	End Rem
	Method ModifiedSingleton(component:SEcsComponent)
		bmx_ecs_modified_component(worldPtr, component.id, component.id)
	End Method

	Rem
	bbdoc: Marks a singleton component as modified by its ID.
	End Rem
	Method ModifiedSingleton(componentId:ULong)
		bmx_ecs_modified_component(worldPtr, componentId, componentId)
	End Method

	Rem
	bbdoc: Deletes an entity from the world.
	End Rem
	Method DeleteEntity(entity:ULong)
		bmx_ecs_delete_entity(worldPtr, entity)
	End Method

	Rem
	bbdoc: Checks if an entity is alive (not deleted).
	End Rem
	Method IsAlive:Int(entity:ULong)
		Return bmx_ecs_is_alive(worldPtr, entity)
	End Method

	Rem
	bbdoc: Begins deferring commands in the world.
	about: When commands are deferred, they are not executed immediately but are instead queued for later execution.
	This can be useful for batching operations or for ensuring that certain operations are performed in a specific order.
	End Rem
	Method DeferBegin:Int()
		Return bmx_ecs_defer_begin(worldPtr)
	End Method

	Rem
	bbdoc: Ends deferring commands in the world.
	returns: #True if deferring was successfully ended, #False otherwise.
	End Rem
	Method DeferEnd:Int()
		Return bmx_ecs_defer_end(worldPtr)
	End Method

	Rem
	bbdoc: Checks if commands are currently being deferred in the world.
	returns: #True if commands are deferred, #False otherwise.
	End Rem
	Method IsDeferred:Int()
		Return bmx_ecs_is_deferred(worldPtr)
	End Method

	Rem
	bbdoc: Adds a pair relationship to an entity.
	End Rem
	Method AddPair(entity:ULong, relation:ULong, target:ULong)
		bmx_ecs_add_pair(worldPtr, entity, relation, target)
	End Method

	Rem
	bbdoc: Checks if an entity has a specific pair relationship.
	End Rem
	Method HasPair:Int(entity:ULong, relation:ULong, target:ULong)
		Return bmx_ecs_has_pair(worldPtr, entity, relation, target)
	End Method

	Rem
	bbdoc: Removes a pair relationship from an entity.
	End Rem
	Method RemovePair(entity:ULong, relation:ULong, target:ULong)
		bmx_ecs_remove_pair(worldPtr, entity, relation, target)
	End Method

	Rem
	bbdoc: Gets the ID of a pair relationship.
	End Rem
	Method PairId:ULong(relation:ULong, target:ULong)
		Return bmx_ecs_pair(relation, target)
	End Method

	Rem
	bbdoc: Gets the target of a pair relationship for an entity, optionally at a specific index if multiple pairs exist.
	End Rem
	Method Target:ULong(entity:ULong, relation:ULong, index:Int = 0)
		Return bmx_ecs_get_target(worldPtr, entity, relation, index)
	End Method

	Rem
	bbdoc: Adds a child entity to a parent entity, establishing a ChildOf relationship.
	End Rem
	Method AddChild(parent:ULong, child:ULong)
		AddPair(child, EcsChildOf, parent)
	End Method

	Rem
	bbdoc: Removes a child entity from a parent entity, removing the ChildOf relationship.
	End Rem
	Method RemoveChild(parent:ULong, child:ULong)
		RemovePair(child, EcsChildOf, parent)
	End Method

	Rem
	bbdoc: Gets the parent of a child entity, if it has one.
	End Rem
	Method Parent:ULong(child:ULong)
		Return Target(child, EcsChildOf)
	End Method

	Rem
	bbdoc: Sets the name of an entity.
	End Rem
	Method SetName(entity:ULong, name:String)
		bmx_ecs_set_name(worldPtr, entity, name)
	End Method

	Rem
	bbdoc: Creates a new query for entities with specific components.
	about: Queries allow you to efficiently iterate over entities that match specific component criteria.
	End Rem
	Method CreateQuery:TEcsQuery(componentIds:ULong[], flags:UInt = 0, cacheKind:EEcsQueryCacheKind = EEcsQueryCacheKind.EcsQueryCacheDefault)
		Local q:TEcsQuery = New TEcsQuery
		q.worldPtr = worldPtr
		q.queryPtr = bmx_ecs_query_create(worldPtr, componentIds, componentIds.Length, q, flags, cacheKind)
		Return q
	End Method

	Rem
	bbdoc: Creates a new query for entities with specific components using a pointer to an array of component IDs and a count of the number of components.
	about: Queries allow you to efficiently iterate over entities that match specific component criteria.
	End Rem
	Method CreateQuery:TEcsQuery(componentIds:ULong Ptr, count:Int, flags:UInt = 0, cacheKind:EEcsQueryCacheKind = EEcsQueryCacheKind.EcsQueryCacheDefault)
		Local q:TEcsQuery = New TEcsQuery
		q.worldPtr = worldPtr
		q.queryPtr = bmx_ecs_query_create(worldPtr, componentIds, count, q, flags, cacheKind)
		Return q
	End Method

	Rem
	bbdoc: Creates a new query for entities with specific components using an array of #SEcsComponent.
	about: Queries allow you to efficiently iterate over entities that match specific component criteria.
	End Rem
	Method CreateQuery:TEcsQuery(components:SEcsComponent[], flags:UInt = 0, cacheKind:EEcsQueryCacheKind = EEcsQueryCacheKind.EcsQueryCacheDefault)
		Local componentIds:ULong Ptr = StackAlloc(components.Length * SizeOf(0:ULong))
		For Local i:Int = 0 Until components.Length
			componentIds[i] = components[i].id
		Next

		Local q:TEcsQuery = New TEcsQuery
		q.worldPtr = worldPtr
		q.queryPtr = bmx_ecs_query_create(worldPtr, componentIds, components.Length, q, flags, cacheKind)
		Return q
	End Method

	Rem
	bbdoc: Creates a new query for entities with specific terms (#SEcsTerm).
	about: Queries allow you to efficiently iterate over entities that match specific component criteria.
	End Rem
	Method CreateQuery:TEcsQuery(terms:SEcsTerm[], flags:UInt = 0, cacheKind:EEcsQueryCacheKind = EEcsQueryCacheKind.EcsQueryCacheDefault)
		Local q:TEcsQuery = New TEcsQuery
		q.worldPtr = worldPtr
		q.queryPtr = bmx_ecs_query_create_terms(worldPtr, terms, terms.Length, q, flags, cacheKind)
		Return q
	End Method

	Rem
	bbdoc: Creates a new query for entities with specific terms (#SEcsTerm) using a pointer to an array of terms and a count of the number of terms.
	about: Queries allow you to efficiently iterate over entities that match specific component criteria.
	End Rem
	Method CreateQuery:TEcsQuery(terms:SEcsTerm Ptr, count:Int, flags:UInt = 0, cacheKind:EEcsQueryCacheKind = EEcsQueryCacheKind.EcsQueryCacheDefault)
		Local q:TEcsQuery = New TEcsQuery
		q.worldPtr = worldPtr
		q.queryPtr = bmx_ecs_query_create_terms(worldPtr, terms, count, q, flags, cacheKind)
		Return q
	End Method

	Rem
	bbdoc: Creates a new ordered query for entities with specific components using an array of component IDs.
	about: Ordered queries allow you to efficiently iterate over entities that match specific component criteria in a specific order.
	End Rem
	Method CreateOrderedQuery:TEcsOrderedQuery(componentIds:ULong[], orderBy:ULong, compare:Int(e1:ULong, p1:Byte Ptr, e2:ULong, p2:Byte Ptr), flags:UInt = 0, cacheKind:EEcsQueryCacheKind = EEcsQueryCacheKind.EcsQueryCacheDefault)
		Local q:TEcsOrderedQuery = New TEcsOrderedQuery
		q.worldPtr = worldPtr
		q.queryPtr = bmx_ecs_ordered_query_create(worldPtr, componentIds, componentIds.Length, orderBy, compare, q, flags, cacheKind)
		Return q
	End Method

	Rem
	bbdoc: Creates a new ordered query for entities with specific components using a pointer to an array of component IDs and a count of the number of components.
	about: Ordered queries allow you to efficiently iterate over entities that match specific component criteria in a specific order.
	End Rem
	Method CreateOrderedQuery:TEcsOrderedQuery(componentIds:ULong Ptr, count:Int, orderBy:ULong, compare:Int(e1:ULong, p1:Byte Ptr, e2:ULong, p2:Byte Ptr), flags:UInt = 0, cacheKind:EEcsQueryCacheKind = EEcsQueryCacheKind.EcsQueryCacheDefault)
		Local q:TEcsOrderedQuery = New TEcsOrderedQuery
		q.worldPtr = worldPtr
		q.queryPtr = bmx_ecs_ordered_query_create(worldPtr, componentIds, count, orderBy, compare, q, flags, cacheKind)
		Return q
	End Method

	Rem
	bbdoc: Creates a new ordered query for entities with specific components using an array of #SEcsComponent.
	about: Ordered queries allow you to efficiently iterate over entities that match specific component criteria in a specific order.
	End Rem
	Method CreateOrderedQuery:TEcsOrderedQuery(component:SEcsComponent[], orderBy:SEcsComponent, compare:Int(e1:ULong, p1:Byte Ptr, e2:ULong, p2:Byte Ptr), flags:UInt = 0, cacheKind:EEcsQueryCacheKind = EEcsQueryCacheKind.EcsQueryCacheDefault)
		Local componentIds:ULong Ptr = StackAlloc(component.Length * SizeOf(0:ULong))
		For Local i:Int = 0 Until component.Length
			componentIds[i] = component[i].id
		Next

		Local q:TEcsOrderedQuery = New TEcsOrderedQuery
		q.worldPtr = worldPtr
		q.queryPtr = bmx_ecs_ordered_query_create(worldPtr, componentIds, component.Length, orderBy.id, compare, q, flags, cacheKind)
		Return q
	End Method

	Rem
	bbdoc: Creates a new ordered query for entities with specific terms (#SEcsTerm).
	about: Ordered queries allow you to efficiently iterate over entities that match specific component criteria in a specific order.
	End Rem
	Method CreateOrderedQuery:TEcsOrderedQuery(terms:SEcsTerm[], orderBy:SEcsComponent, compare:Int(e1:ULong, p1:Byte Ptr, e2:ULong, p2:Byte Ptr), flags:UInt = 0, cacheKind:EEcsQueryCacheKind = EEcsQueryCacheKind.EcsQueryCacheDefault)
		Local q:TEcsOrderedQuery = New TEcsOrderedQuery
		q.worldPtr = worldPtr
		q.queryPtr = bmx_ecs_ordered_query_create_terms(worldPtr, terms, terms.Length, orderBy.id, compare, q, flags, cacheKind)
		Return q
	End Method

	Rem
	bbdoc: Creates a new ordered query for entities with specific terms (#SEcsTerm) using a pointer to an array of terms and a count of the number of terms.
	about: Ordered queries allow you to efficiently iterate over entities that match specific component criteria in a specific order.
	End Rem
	Method CreateOrderedQuery:TEcsOrderedQuery(terms:SEcsTerm Ptr, count:Int, orderBy:ULong, compare:Int(e1:ULong, p1:Byte Ptr, e2:ULong, p2:Byte Ptr), flags:UInt = 0, cacheKind:EEcsQueryCacheKind = EEcsQueryCacheKind.EcsQueryCacheDefault)
		Local q:TEcsOrderedQuery = New TEcsOrderedQuery
		q.worldPtr = worldPtr
		q.queryPtr = bmx_ecs_ordered_query_create_terms(worldPtr, terms, count, orderBy, compare, q, flags, cacheKind)
		Return q
	End Method

	Rem
	bbdoc: Creates a new grouped query for entities with specific terms (#SEcsTerm).
	about: Grouped queries allow you to efficiently iterate over entities that match specific component criteria, grouped by a specific component.
	End Rem
	Method CreateGroupedQuery:TEcsQuery(terms:SEcsTerm[], groupBy:ULong, flags:UInt = 0, cacheKind:EEcsQueryCacheKind = EEcsQueryCacheKind.EcsQueryCacheDefault)
		Local q:TEcsQuery = New TEcsQuery
		q.worldPtr = worldPtr
		q.queryPtr = bmx_ecs_grouped_query_create_terms(worldPtr, terms, terms.Length, groupBy, q, flags, cacheKind)
		Return q
	End Method

	Rem
	bbdoc: Creates a new grouped query for entities with specific terms (#SEcsTerm) using a pointer to an array of terms and a count of the number of terms.
	about: Grouped queries allow you to efficiently iterate over entities that match specific component criteria, grouped by a specific component.
	End Rem
	Method CreateGroupedQuery:TEcsQuery(terms:SEcsTerm Ptr, count:Int, groupBy:ULong, flags:UInt = 0, cacheKind:EEcsQueryCacheKind = EEcsQueryCacheKind.EcsQueryCacheDefault)
		Local q:TEcsQuery = New TEcsQuery
		q.worldPtr = worldPtr
		q.queryPtr = bmx_ecs_grouped_query_create_terms(worldPtr, terms, count, groupBy, q, flags, cacheKind)
		Return q
	End Method

	Rem
	bbdoc: Creates a new ordered grouped query for entities with specific terms (#SEcsTerm).
	about: Ordered grouped queries allow you to efficiently iterate over entities that match specific component criteria, grouped by a specific component and ordered by another component.
	End Rem
	Method CreateOrderedGroupedQuery:TEcsOrderedQuery(terms:SEcsTerm[], groupBy:ULong, orderBy:ULong, compare:Int(e1:ULong, p1:Byte Ptr, e2:ULong, p2:Byte Ptr), flags:UInt = 0, cacheKind:EEcsQueryCacheKind = EEcsQueryCacheKind.EcsQueryCacheDefault)
		Local q:TEcsOrderedQuery = New TEcsOrderedQuery
		q.worldPtr = worldPtr
		q.queryPtr = bmx_ecs_grouped_ordered_query_create_terms(worldPtr, terms, terms.Length, groupBy, orderBy, compare, q, flags, cacheKind)
		Return q
	End Method

	Rem
	bbdoc: Marks a component as modified for an entity.
	about: This is used to notify the ECS that the data for a component has changed, so that systems that depend on that component can be re-evaluated.
	End Rem
	Method ModifiedComponent(entity:ULong, component:SEcsComponent)
    	bmx_ecs_modified_component(worldPtr, entity, component.id)
	End Method

	Rem
	bbdoc: Creates a new prefab.
	about: A prefab is a template entity that can be instantiated to create new entities with the same components and data.
	End Rem
	Method NewPrefab:ULong(name:String)
		Return bmx_ecs_new_prefab(worldPtr, name)
	End Method

	Rem
	bbdoc: Checks if an entity is a prefab.
	about: Prefabs are template entities that can be instantiated to create new entities with the same components and data.
	This method checks if the given entity is a prefab.
	End Rem
	Method IsPrefab:Int(entity:ULong)
		Return bmx_ecs_is_prefab(worldPtr, entity)
	End Method

	Rem
	bbdoc: Instantiates a prefab entity.
	about: This method creates a new entity based on the given prefab.
	End Rem
	Method Instantiate:ULong(prefabId:ULong)
		Return bmx_ecs_instantiate(worldPtr, prefabId)
	End Method

	Rem
	bbdoc: Applies a policy to a component when an entity is instantiated from a prefab.
	about: This method sets a policy for how a component should be handled when an entity is instantiated from a prefab.
	The policy can specify whether the component should be copied, shared, or ignored.
	End Rem
	Method SetOnInstantiate(component:SEcsComponent, policyId:ULong)
		bmx_ecs_set_on_instantiate(worldPtr, component.id, policyId)
	End Method

	Rem
	bbdoc: Serializes an entity to a JSON string.
	about: This method converts the given entity and its components into a JSON representation.
	End Rem
	Method EntityToJson:String(entity:ULong)
		Return bmx_ecs_entity_to_json(worldPtr, entity)
	End Method

	Rem
	bbdoc: Serializes a component of an entity to a JSON string.
	about: This method converts the specified component of the given entity into a JSON representation.
	End Rem
	Method ComponentToJson:String(entity:ULong, component:SEcsComponent)
		Return bmx_ecs_component_to_json(worldPtr, entity, component.id)
	End Method

	Rem
	bbdoc: Looks up an entity by name and returns its ID.
	about: This method searches for an entity with the specified name and returns its unique ID.
	If no entity with the given name exists, it returns 0.
	End Rem
	Method Lookup:ULong(name:String)
		Return bmx_ecs_lookup(worldPtr, name)
	End Method

	Rem
	bbdoc: Retrieves the name of an entity.
	about: This method returns the name of the specified entity.
	If the entity does not have a name, it returns an empty string.
	End Rem
	Method GetName:String(entity:ULong)
		Return bmx_ecs_get_name(worldPtr, entity)
	End Method

	Rem
	bbdoc: Retrieves the full path of an entity in the hierarchy.
	about: This method returns the full path of the specified entity, including its parent entities.
	If the entity does not have a path, it returns an empty string.
	End Rem
	Method GetPath:String(entity:ULong)
		Return bmx_ecs_get_path(worldPtr, entity)
	End Method

	Rem
	bbdoc: Looks up a child entity by name under a specified parent entity.
	about: This method searches for a child entity with the specified name under the given parent entity and returns its unique ID.
	If no child entity with the given name exists under the parent, it returns 0.
	End Rem
	Method LookupChild:ULong(parent:ULong, name:String)
		Return bmx_ecs_lookup_child(worldPtr, parent, name)
	End Method

	Rem
	bbdoc: Retrieves the path of a child entity relative to a specified parent entity.
	about: This method returns the path of the specified child entity relative to the given parent entity.
	If the child entity is not a descendant of the parent, it returns an empty string.
	End Rem
	Method GetPathFrom:String(parent:ULong, child:ULong)
		Return bmx_ecs_get_path_from(worldPtr, parent, child)
	End Method

	Rem
	bbdoc: Enables an entity, allowing it to be processed by systems.
	about: This method marks the specified entity as enabled, meaning it will be included in system processing and queries.
	End Rem
	Method Enable(entity:ULong)
		bmx_ecs_enable(worldPtr, entity, True)
	End Method

	Rem
	bbdoc: Disables an entity, preventing it from being processed by systems.
	about: This method marks the specified entity as disabled, meaning it will be excluded from system processing and queries.
	End Rem
	Method Disable(entity:ULong)
		bmx_ecs_enable(worldPtr, entity, False)
	End Method

	Rem
	bbdoc: Checks if an entity is enabled.
	about: This method returns #True if the specified entity is enabled and will be processed by systems, or #False if it is disabled.
	End Rem
	Method IsEnabled:Int(entity:ULong)
		Return bmx_ecs_is_enabled(worldPtr, entity)
	End Method

	Rem
	bbdoc: Sets whether a component can be toggled on or off for entities.
	about: This method configures the specified component to be toggleable, allowing it to be enabled or disabled on entities at runtime.
	End Rem
	Method SetCanToggle(component:SEcsComponent)
		bmx_ecs_set_can_toggle(worldPtr, component.id)
	End Method

	Rem
	bbdoc: Enables a component for an entity, allowing it to be processed by systems.
	about: This method marks the specified component as enabled for the given entity, meaning it will be included in system processing and queries.
	End Rem
	Method EnableComponent(entity:ULong, component:SEcsComponent)
		bmx_ecs_enable_component(worldPtr, entity, component.id, True)
	End Method

	Rem
	bbdoc: Enables a component for an entity, allowing it to be processed by systems.
	about: This method marks the specified component as enabled for the given entity, meaning it will be included in system processing and queries.
	End Rem
	Method EnableComponent(entity:ULong, componentId:ULong)
		bmx_ecs_enable_component(worldPtr, entity, componentId, True)
	End Method

	Rem
	bbdoc: Disables a component for an entity, preventing it from being processed by systems.
	about: This method marks the specified component as disabled for the given entity, meaning it will be excluded from system processing and queries.
	End Rem
	Method DisableComponent(entity:ULong, component:SEcsComponent)
		bmx_ecs_enable_component(worldPtr, entity, component.id, False)
	End Method

	Rem
	bbdoc: Disables a component for an entity, preventing it from being processed by systems.
	about: This method marks the specified component as disabled for the given entity, meaning it will be excluded from system processing and queries.
	End Rem
	Method DisableComponent(entity:ULong, componentId:ULong)
		bmx_ecs_enable_component(worldPtr, entity, componentId, False)
	End Method

	Rem
	bbdoc: Checks if a component is enabled for an entity.
	about: This method returns #True if the specified component is enabled for the given entity and will be processed by systems, or #False if it is disabled.
	End Rem
	Method IsComponentEnabled:Int(entity:ULong, component:SEcsComponent)
		Return bmx_ecs_is_component_enabled(worldPtr, entity, component.id)
	End Method

	Rem
	bbdoc: Checks if a component is enabled for an entity.
	about: This method returns #True if the specified component is enabled for the given entity and will be processed by systems, or #False if it is disabled.
	End Rem
	Method IsComponentEnabled:Int(entity:ULong, componentId:ULong)
		Return bmx_ecs_is_component_enabled(worldPtr, entity, componentId)
	End Method

	Rem
	bbdoc: Sets the target frames per second (FPS) for the world.
	about: This method configures the world to aim for the specified FPS when updating and running systems.
	It can be used to control the update rate of the ECS.
	End Rem
	Method SetTargetFps(fps:Float)
		bmx_ecs_set_target_fps(worldPtr, fps)
	End Method

	Rem
	bbdoc: Quits the ECS world.
	about: This method signals the ECS world to quit, stopping all systems and updates.
	End Rem
	Method Quit()
		bmx_ecs_quit(worldPtr)
	End Method

	Rem
	bbdoc: Checks if the ECS world should quit.
	about: This method returns #True if the ECS world has been signaled to quit, or #False otherwise.
	End Rem
	Method ShouldQuit:Int()
		Return bmx_ecs_should_quit(worldPtr)
	End Method

	Rem
	bbdoc: Sets the interval for a system.
	about: The interval specifies how often the system should run, in seconds.
	End Rem
	Method SetSystemInterval(system:TEcsSystem, interval:Float)
		bmx_ecs_set_system_interval(worldPtr, system.id, interval)
	End Method

	Rem
	bbdoc: Sets the rate for a system.
	about: The rate specifies how many times per second the system should run.
	End Rem
	Method SetSystemRate(system:TEcsSystem, rate:Int)
		bmx_ecs_set_system_rate(worldPtr, system.id, rate)
	End Method

	Rem
	bbdoc: Sets the rate and tick source for a system.
	about: The rate specifies how many times per second the system should run, and the tick source specifies which clock to use for timing.
	End Rem
	Method SetSystemRate(system:TEcsSystem, rate:Int, tickSource:ULong)
		bmx_ecs_set_system_rate_source(worldPtr, system.id, rate, tickSource)
	End Method

	Rem
	bbdoc: Creates a new timer in the world.
	about: A timer is a special entity that can be used to trigger events or systems at specific intervals.
	The timer will have a name and an interval in seconds.
	End Rem
	Method NewTimer:ULong(name:String, interval:Float)
		Return bmx_ecs_new_timer(worldPtr, name, interval)
	End Method

	Rem
	bbdoc: Creates a new rate filter in the world.
	about: A rate filter is a special entity that can be used to control the execution rate of systems or events.
	The rate filter will have a name, a rate in ticks per second, and an optional tick source.
	End Rem
	Method NewRateFilter:ULong(name:String, rate:Int, tickSource:ULong = 0)
		Return bmx_ecs_new_rate_filter(worldPtr, name, rate, tickSource)
	End Method

	Rem
	bbdoc: Clears all components from an entity, effectively resetting it to an empty state.
	about: This method removes all components from the specified entity, leaving it with no data or relationships.
	End Rem
	Method ClearEntity(entity:ULong)
		bmx_ecs_clear_entity(worldPtr, entity)
	End Method

	Rem
	bbdoc: Clones an entity, optionally copying its component values.
	about: This method creates a new entity that is a copy of the specified entity.
	If @copyValue is #True, the component values will be copied to the new entity; if #False, the new entity will have the same components but with default values.
	End Rem
	Method CloneEntity:ULong(entity:ULong, copyValue:Int = True)
		Return bmx_ecs_clone_entity(worldPtr, entity, copyValue)
	End Method

	Rem
	bbdoc: Deletes all entities that have a specific component.
	about: This method removes all entities from the world that have the specified component, effectively deleting them.
	End Rem
	Method DeleteWith(component:SEcsComponent)
		bmx_ecs_delete_with(worldPtr, component.id)
	End Method

	Rem
	bbdoc: Removes a specific component from all entities that have it.
	about: This method removes the specified component from all entities in the world that have it, effectively clearing that component from the world.
	End Rem
	Method RemoveAll(component:SEcsComponent)
		bmx_ecs_remove_all(worldPtr, component.id)
	End Method

	Rem
	bbdoc: Deletes all entities that have a specific pair relationship.
	about: This method removes all entities from the world that have the specified pair relationship, effectively deleting them.
	End Rem
	Method DeleteWith(relation:ULong, target:ULong)
		bmx_ecs_delete_with(worldPtr, PairId(relation, target))
	End Method

	Rem
	bbdoc: Deletes all entities that have a specific pair relationship.
	about: This method removes all entities from the world that have the specified pair relationship, effectively deleting them.
	End Rem
	Method DeleteWith(relation:SEcsComponent, target:ULong)
		DeleteWith(relation.id, target)
	End Method

	Rem
	bbdoc: Deletes all entities that have a specific pair relationship.
	about: This method removes all entities from the world that have the specified pair relationship, effectively deleting them.
	End Rem
	Method DeleteWith(relation:ULong, target:SEcsComponent)
		DeleteWith(relation, target.id)
	End Method

	Rem
	bbdoc: Deletes all entities that have a specific pair relationship.
	about: This method removes all entities from the world that have the specified pair relationship, effectively deleting them.
	End Rem
	Method DeleteWith(relation:SEcsComponent, target:SEcsComponent)
		DeleteWith(relation.id, target.id)
	End Method

	Rem
	bbdoc: Removes a specific pair relationship from all entities that have it.
	about: This method removes the specified pair relationship from all entities in the world that have it, effectively clearing that relationship from the world.
	End Rem
	Method RemoveAll(relation:ULong, target:ULong)
		bmx_ecs_remove_all(worldPtr, PairId(relation, target))
	End Method

	Rem
	bbdoc: Removes a specific pair relationship from all entities that have it.
	about: This method removes the specified pair relationship from all entities in the world that have it, effectively clearing that relationship from the world.
	End Rem
	Method RemoveAll(relation:SEcsComponent, target:ULong)
		RemoveAll(relation.id, target)
	End Method

	Rem
	bbdoc: Removes a specific pair relationship from all entities that have it.
	about: This method removes the specified pair relationship from all entities in the world that have it, effectively clearing that relationship from the world.
	End Rem
	Method RemoveAll(relation:ULong, target:SEcsComponent)
		RemoveAll(relation, target.id)
	End Method

	Rem
	bbdoc: Removes a specific pair relationship from all entities that have it.
	about: This method removes the specified pair relationship from all entities in the world that have it, effectively clearing that relationship from the world.
	End Rem
	Method RemoveAll(relation:SEcsComponent, target:SEcsComponent)
		RemoveAll(relation.id, target.id)
	End Method

	Rem
	bbdoc: Sets a brief description for entity.
	about: The brief description is stored in `(EcsIdentifier, EcsBrief)`.
	End Rem
	Method SetBrief(entity:ULong, text:String)
		bmx_ecs_doc_set_brief(worldPtr, entity, text)
	End Method

	Rem
	bbdoc: Retrieves the brief description for entity.
	about: The brief description is stored in `(EcsIdentifier, EcsBrief)`.
	End Rem
	Method GetBrief:String(entity:ULong)
		Return bmx_ecs_doc_get_brief(worldPtr, entity)
	End Method

	Rem
	bbdoc: Sets a detailed description for entity.
	about: The detailed description is stored in `(EcsIdentifier, EcsDetail)`.
	End Rem
	Method SetDetail(entity:ULong, text:String)
		bmx_ecs_doc_set_detail(worldPtr, entity, text)
	End Method

	Rem
	bbdoc: Retrieves the detailed description for entity.
	about: The detailed description is stored in `(EcsIdentifier, EcsDetail)`.
	End Rem
	Method GetDetail:String(entity:ULong)
		Return bmx_ecs_doc_get_detail(worldPtr, entity)
	End Method

	Rem
	bbdoc: Sets a color for entity.
	about: The color is stored in `(EcsIdentifier, EcsColor)`.
	End Rem
	Method SetColor(entity:ULong, color:String)
		bmx_ecs_doc_set_color(worldPtr, entity, color)
	End Method

	Rem
	bbdoc: Retrieves the color for entity.
	about: The color is stored in `(EcsIdentifier, EcsColor)`.
	End Rem
	Method GetColor:String(entity:ULong)
		Return bmx_ecs_doc_get_color(worldPtr, entity)
	End Method

	Rem
	bbdoc: Sets a link for entity.
	about: The link is stored in `(EcsIdentifier, EcsLink)`.
	End Rem
	Method SetLink(entity:ULong, link:String)
		bmx_ecs_doc_set_link(worldPtr, entity, link)
	End Method

	Rem
	bbdoc: Retrieves the link for entity.
	about: The link is stored in `(EcsIdentifier, EcsLink)`.
	End Rem
	Method GetLink:String(entity:ULong)
		Return bmx_ecs_doc_get_link(worldPtr, entity)
	End Method

	Rem
	bbdoc: Sets a brief description for a component.
	about: The brief description is stored in `(EcsIdentifier, EcsBrief)`.
	End Rem
	Method SetBrief(component:SEcsComponent, text:String)
		SetBrief(component.id, text)
	End Method

	Rem
	bbdoc: Retrieves the brief description for a component.
	about: The brief description is stored in `(EcsIdentifier, EcsBrief)`.
	End Rem
	Method GetBrief:String(component:SEcsComponent)
		Return GetBrief(component.id)
	End Method

	Rem
	bbdoc: Sets an alias for entity.
	about: An entity can be looked up using its alias from the root scope without
 	providing the fully qualified name if its parent. An entity can only have
	a single alias.
 
	The alias is stored in `(EcsIdentifier, EcsAlias)`.
	End Rem
	Method SetAlias(entity:ULong, text:String)
		bmx_ecs_set_alias(worldPtr, entity, text)
	End Method

	Rem
	bbdoc: Sets a symbol for entity.
	about: The symbol is stored in `(EcsIdentifier, EcsSymbol)`.
	End Rem
	Method SetSymbol(entity:ULong, symbol:String)
		bmx_ecs_set_symbol(worldPtr, entity, symbol)
	End Method

	Rem
	bbdoc: Retrieves the symbol for entity.
	about: The symbol is stored in `(EcsIdentifier, EcsSymbol)`.
	End Rem
	Method Symbol:String(entity:ULong)
		Return bmx_ecs_get_symbol(worldPtr, entity)
	End Method

	Rem
	bbdoc: Creates a new phase with the specified name and optional dependency.
	about: A phase is a stage in the execution of systems. Systems can be assigned to different phases to control the order in which they
	are executed. For example, you might have a "Initialization" phase, a "Simulation" phase, and a "Rendering" phase. Systems in
	the "Initialization" phase would run before systems in the "Simulation" phase, which would run before systems in the "Rendering" phase. You can create phases using the #NewPhase method, and set the phase of a system using the #SetSystemPhase method.
	End Rem
	Method NewPhase:ULong(name:String, dependsOn:ULong = 0)
		Return bmx_ecs_new_phase(worldPtr, name, dependsOn)
	End Method

	Rem
	bbdoc: Sets the phase of a system.
	about: A phase is a stage in the execution of systems. Systems can be assigned to different phases to control the order in which they
	are executed. For example, you might have a "Initialization" phase, a "Simulation" phase, and a "Rendering" phase. Systems in
	the "Initialization" phase would run before systems in the "Simulation" phase, which would run before systems in the
	"Rendering" phase. You can create phases using the #NewPhase method, and set the phase of a system using the #SetSystemPhase method.
	End Rem
	Method SetSystemPhase(system:TEcsSystem, phase:ULong)
		bmx_ecs_set_system_phase(worldPtr, system.id, phase)
	End Method

	Rem
	bbdoc: Creates a new pipeline with the specified name and expression.
	about: A pipeline is a sequence of systems that are executed in a specific order.
	You can create pipelines using the #NewPipeline method, and set the current pipeline using the #SetPipeline method.
	The expression defines the order of systems in the pipeline.
	For example, "A;B;C" means that system A will run first, followed by system B, and then system C. You can also use parentheses to group
		systems, e.g. "A;(B;C)" means that system A will run first, and then systems B and C will run in parallel.
	End Rem
	Method NewPipeline:ULong(name:String, expr:String)
		Return bmx_ecs_new_pipeline(worldPtr, name, expr)
	End Method

	Rem
	bbdoc: Sets the currently active pipeline.
	about: A pipeline is a sequence of systems that are executed in a specific order.
	You can create pipelines using the #NewPipeline method, and set the current pipeline using the #SetPipeline method.
	End Rem
	Method SetPipeline(pipeline:ULong)
		bmx_ecs_set_pipeline(worldPtr, pipeline)
	End Method

	Rem
	bbdoc: Retrieves the currently set pipeline.
	about: A pipeline is a sequence of systems that are executed in a specific order.
	You can create pipelines using the `NewPipeline` method, and set the current pipeline using the #SetPipeline method.
	End Rem
	Method GetPipeline:ULong()
		Return bmx_ecs_get_pipeline(worldPtr)
	End Method

	Rem
	bbdoc: Runs the specified pipeline, or the currently set pipeline if none is specified.
	about: A pipeline is a sequence of systems that are executed in a specific order.
	You can create pipelines using the #NewPipeline method, and set the current pipeline using the #SetPipeline method.
	If you don't specify a pipeline, the currently set pipeline will be run. The @deltaTime parameter allows you to specify the
	time elapsed since the last update, which can be used for time-based calculations in systems.
	End Rem
	Method RunPipeline(pipeline:ULong = 0, deltaTime:Float = 0.0)
		bmx_ecs_run_pipeline(worldPtr, pipeline, deltaTime)
	End Method

	Rem
	bbdoc: Enables the REST server for the ECS world.
	about: The REST server allows you to interact with the ECS world using HTTP requests.
	You can use this to inspect the state of the world, query entities, and perform other operations.
	The default port is 27750, but you can specify a different port if needed.
	End Rem
	Method EnableRestServer(port:Int = 27750)
		bmx_ecs_enable_rest_server(worldPtr, port)
	End Method

	Rem
	bbdoc: Enables the collection of statistics for the ECS world.
	about: Enabling statistics allows you to monitor the performance and resource usage of the ECS world.
	You can retrieve statistics such as the number of entities, components, systems, and more.
	End Rem
	Method EnableStats()
		bmx_ecs_enable_stats(worldPtr)
	End Method

	Rem
	bbdoc: Retrieves the current statistics for the ECS world.
	returns: #True if the statistics were successfully retrieved, #False otherwise.
	about: The statistics are returned in a #SEcsWorldStats structure.
	End Rem
	Method GetStats:Int(stats:SEcsWorldStats Var)
		Return bmx_ecs_get_stats(worldPtr, stats)
	End Method

	Method Delete()
		If worldPtr Then
			 ecs_fini(worldPtr)
			 worldPtr = Null
		End If
	End Method
End Type

Rem
bbdoc: Represents a system in the ECS world.
about: A system is a function that processes entities with specific components. Systems can be created, configured, and run within the ECS world.
End Rem
Type TEcsSystem

	Field id:ULong
    Field iter:TEcsIter = New TEcsIter
    Field callback( it:TEcsIter )

    Function _Invoke(system:TEcsSystem, iterPtr:Byte Ptr) { nomangle }
        system.iter.iterPtr = iterPtr
        system.callback(system.iter)
        system.iter.iterPtr = Null
    End Function

End Type

Rem
bbdoc: Represents an iterator for querying entities in the ECS world.
about: An iterator allows you to traverse through entities that match specific query criteria.
You can access component data, entity IDs, and other information for each entity in the query.
End Rem
Type TEcsIter
	Field iterPtr:Byte Ptr

	Rem
	bbdoc: Returns the number of entities in the current iteration.
	about: This method returns the count of entities that are currently being iterated over in the query. It can be used to determine how many entities match the query criteria.
	End Rem
	Method Count:Int()
        Return bmx_ecs_iter_count(iterPtr)
    End Method

	Rem
	bbdoc: Retrieves the component data for a specific component in the current iteration.
	returns: #True if the component data was successfully retrieved, #False otherwise.
	about: This method retrieves the data for the specified component at the given index in the current iteration. The data is returned as a pointer to a byte array, which can be cast to the appropriate component type.
	End Rem
	Method Component(component:SEcsComponent, index:Int, data:Byte Ptr Ptr)
		bmx_ecs_field_w_size(iterPtr, component.size, index, data)
	End Method

	Rem
	bbdoc: Retrieves the entity ID for a specific index in the current iteration.
	returns: The unique ID of the entity at the specified index in the current iteration.
	about: This method returns the entity ID for the entity at the given index in the current iteration. The entity ID can be used to access the entity's components and other information.
	End Rem
	Method Entity:ULong(index:Int)
		Return bmx_ecs_iter_entity(iterPtr, index)
	End Method

	Rem
	bbdoc: Checks if a component is owned by the entity or shared with other entities.
	returns: #True if the component is owned by the entity, #False if it is shared with other entities.
	about: This method checks if the component at the specified index in the current iteration is owned by the entity (self) or shared with other entities. Owned components have unique data for each entity, while shared components have a single instance of data that is shared among multiple entities.
	End Rem
	Method ComponentIsSelf:Int(index:Int)
    	Return bmx_ecs_iter_field_is_self(iterPtr, index)
	End Method

	Rem
	bbdoc: Checks if a component is shared with other entities.
	returns: #True if the component is shared with other entities, #False if it is owned by the entity.
	about: This method checks if the component at the specified index in the current iteration is shared with other entities. Shared components have a single instance of data that is shared among multiple entities, while owned components have unique data for each entity.
	End Rem
	Method ComponentIsShared:Int(index:Int)
		Return Not ComponentIsSelf(index)
	End Method

	Rem
	bbdoc:
	returns: #True if the component is shared, #False if it is owned by the entity.
	about:
	When "shared", the component data is shared with other entities, and there is only a single instance of the component data. When "owned", the component data is unique to the entity.
	So, you might have a component that is shared by multiple entities, and when you modify the component data, it will affect all entities that share that component. When the component is owned by the entity, modifying the component data will only affect that specific entity.
	
	```blitzmax
	Local p:SPosition Ptr
	If it.ComponentShared(position, 0, Varptr p) Then
		' p[0] is shared
	Else
		' p[i] is per-entity
	End If
	```
	End Rem
	Method ComponentShared:Int(component:SEcsComponent, index:Int, data:Byte Ptr Ptr)
		bmx_ecs_field_w_size(iterPtr, component.size, index, data)
		Return Not ComponentIsSelf(index)
	End Method

	Rem
	bbdoc: Retrieves the delta time for the current iteration.
	returns: The time elapsed since the last iteration, in seconds.
	about: This method returns the delta time for the current iteration, which can be used for time-based calculations in systems. The delta time represents the time elapsed since the last update, allowing for smooth and consistent movement or behavior of entities over time.
	End Rem
	Method DeltaTime:Float()
		Return bmx_ecs_iter_delta_time(iterPtr)
	End Method

	Rem
	bbdoc: Retrieves the field ID for a specific index in the current iteration.
	returns: The unique ID of the field at the specified index in the current iteration.
	about: This method returns the field ID for the field at the given index in the current iteration. The field ID can be used to identify the specific component or relationship being accessed in the query.
	End Rem
	Method FieldId:ULong(index:Int)
		Return bmx_ecs_iter_field_id(iterPtr, index)
	End Method

	Rem
	bbdoc: Retrieves the first entity in a pair relationship for a specific index in the current iteration.
	returns: The unique ID of the first entity in the pair relationship at the specified index in the current iteration.
	about: This method returns the first entity ID in a pair relationship for the field at the given index in the current iteration. Pair relationships are used to represent relationships between entities, such as parent-child relationships or component dependencies.
	End Rem
	Method PairFirst:ULong(index:Int)
		Return bmx_ecs_iter_pair_first(iterPtr, index)
	End Method

	Rem
	bbdoc: Retrieves the second entity in a pair relationship for a specific index in the current iteration.
	returns: The unique ID of the second entity in the pair relationship at the specified index in the current iteration.
	about: This method returns the second entity ID in a pair relationship for the field at the given index in the current iteration. Pair relationships are used to represent relationships between entities, such as parent-child relationships or component dependencies.
	End Rem
	Method PairSecond:ULong(index:Int)
		Return bmx_ecs_iter_pair_second(iterPtr, index)
	End Method

	Rem
	bbdoc: Checks if the current iteration is valid.
	returns: #True if the current iteration is valid, #False otherwise.
	about: This method checks if the current iteration is valid, meaning that there are entities to
	Method IsTrue:Int()
		Return bmx_ecs_iter_is_true(iterPtr)
	End Method

	Rem
	bbdoc: Checks if any components have changed since the last iteration.
	returns: #True if any components have changed, #False otherwise.
	about: This method checks if any components in the current iteration have changed since the last iteration. This can be useful for determining if systems need to re-evaluate entities based on changes to their components.
	End Rem
	Method Changed:Int()
		Return bmx_ecs_iter_changed(iterPtr)
	End Method

	Rem
	bbdoc: Skips the current entity in the iteration and moves to the next one.
	about: This method allows you to skip the current entity in the iteration and move to the next one. This can be useful if you want to ignore certain entities based on specific conditions during iteration.
	End Rem
	Method Skip()
		bmx_ecs_iter_skip(iterPtr)
	End Method

End Type

Rem
bbdoc: Represents a query for entities in the ECS world.
about: A query allows you to retrieve entities that match specific component criteria. You can create queries, iterate over the results, and access component data for each entity that matches the query.
End Rem
Type TEcsQuery

	Field worldPtr:Byte Ptr
	Field queryPtr:Byte Ptr
	Field _iter:TEcsIter = New TEcsIter
	Field queryIter:TEcsQueryIter = New TEcsQueryIter(Self)
	Field _callback(iter:TEcsIter)

	Method ForEach(callback(iter:TEcsIter))
		_callback = callback
		bmx_ecs_query_each(worldPtr, queryPtr)
	End Method

	Method Iter:TEcsQueryIter()
		bmx_ecs_query_reset(queryPtr)

		queryIter.iterPtr = bmx_ecs_query_current(queryPtr)

		Return queryIter
	End Method

	Method IterGroup:TEcsQueryIter(groupId:ULong)
		bmx_ecs_query_reset_group(queryPtr, groupId)
		queryIter.iterPtr = bmx_ecs_query_current(queryPtr)
		Return queryIter
	End Method

	Function _Invoke(query:TEcsQuery, cIter:Byte Ptr) { nomangle }
		query._iter.iterPtr = cIter
		query._callback(query._iter)
		query._iter.iterPtr = Null
	End Function

	Method Delete()
		If queryPtr Then
			bmx_ecs_query_destroy(worldPtr, queryPtr)
			queryPtr = Null
		End If
	End Method

End Type

Type TEcsQueryIter Extends TEcsIter

	Field query:TEcsQuery

	Method New(query:TEcsQuery)
		Self.query = query
	End Method

	Method Advance:Int()
		Return bmx_ecs_query_advance(query.queryPtr)
	End Method

End Type

Type TEcsOrderedQuery Extends TEcsQuery

End Type

Type TEcsObserver

    Field worldPtr:Byte Ptr
    Field id:ULong
    Field iter:TEcsIter = New TEcsIter
    Field callback(iter:TEcsIter)

    Function _Invoke(observer:TEcsObserver, iterPtr:Byte Ptr) { nomangle }
        observer.iter.iterPtr = iterPtr
        observer.callback(observer.iter)
        observer.iter.iterPtr = Null
    End Function

End Type

