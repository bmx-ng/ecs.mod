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


Import "source.bmx"



Extern

	Function ecs_mini:Byte Ptr()
	Function ecs_fini(world:Byte Ptr)
	Function ecs_init:Byte Ptr()
	Function ecs_new:ULong(worldPtr:Byte Ptr)

	Function bmx_ecs_quit(worldPtr:Byte Ptr)
	Function bmx_ecs_should_quit:Int(worldPtr:Byte Ptr)

	Function bmx_ecs_new_entity:ULong(worldPtr:Byte Ptr, name:String)

	Function bmx_ecs_register_component:ULong(worldPtr:Byte Ptr, name:String, size:Size_T, alignment:Size_T)
	Function bmx_ecs_register_system:ULong(worldPtr:Byte Ptr, name:String, phase:ULong, componentIds:ULong Ptr, componentCount:Int, system:Object)
	Function bmx_ecs_register_system_terms:ULong(worldPtr:Byte Ptr, name:String, phase:ULong, terms:SEcsTerm Ptr, termCount:Int, system:Object)
	Function bmx_ecs_set_component(worldPtr:Byte Ptr, entityId:ULong, componentId:ULong, size:Size_T, data:Byte Ptr)
	Function bmx_ecs_progress:Int(worldPtr:Byte Ptr, deltaTime:Float)
	Function bmx_ecs_run(worldPtr:Byte Ptr, systemId:ULong, deltaTime:Float)
	Function bmx_ecs_get_component:Int(worldPtr:Byte Ptr, entityId:ULong, componentId:ULong, data:Byte Ptr Ptr)
	Function bmx_ecs_has_component:Int(worldPtr:Byte Ptr, entityId:ULong, componentId:ULong)
	Function bmx_ecs_remove_component(worldPtr:Byte Ptr, entityId:ULong, componentId:ULong)
	Function bmx_ecs_delete_entity(worldPtr:Byte Ptr, entityId:ULong)
	Function bmx_ecs_is_alive:Int(worldPtr:Byte Ptr, entityId:ULong)
	Function bmx_ecs_add_component(worldPtr:Byte Ptr, entityId:ULong, componentId:ULong)
	Function bmx_ecs_query_create:Byte Ptr(worldPtr:Byte Ptr, componentIds:ULong Ptr, componentCount:Int, query:Object, flags:UInt, cacheKind:EEcsQueryCacheKind)
	Function bmx_ecs_ordered_query_create:Byte Ptr(worldPtr:Byte Ptr, componentIds:ULong Ptr, componentCount:Int, orderById:ULong, callback:Int(e1:ULong, p1:Byte Ptr, e2:ULong, p2:Byte Ptr), query:Object, flags:UInt, cacheKind:EEcsQueryCacheKind)
	Function bmx_ecs_query_create_terms:Byte Ptr(worldPtr:Byte Ptr, terms:SEcsTerm Ptr, termCount:Int, query:Object, flags:UInt, cacheKind:EEcsQueryCacheKind)
	Function bmx_ecs_grouped_query_create_terms:Byte Ptr(worldPtr:Byte Ptr, terms:SEcsTerm Ptr, termCount:Int, groupBy:ULong, query:Object, flags:UInt, cacheKind:EEcsQueryCacheKind)
	Function bmx_ecs_ordered_query_create_terms:Byte Ptr(worldPtr:Byte Ptr, terms:SEcsTerm Ptr, termCount:Int, orderById:ULong, callback:Int(e1:ULong, p1:Byte Ptr, e2:ULong, p2:Byte Ptr), query:Object, flags:UInt, cacheKind:EEcsQueryCacheKind)
	Function bmx_ecs_grouped_ordered_query_create_terms:Byte Ptr(worldPtr:Byte Ptr, terms:SEcsTerm Ptr, termCount:Int, groupBy:ULong, orderById:ULong, callback:Int(e1:ULong, p1:Byte Ptr, e2:ULong, p2:Byte Ptr), query:Object, flags:UInt, cacheKind:EEcsQueryCacheKind)

	Function bmx_ecs_defer_begin:Int(worldPtr:Byte Ptr)
	Function bmx_ecs_defer_end:Int(worldPtr:Byte Ptr)
	Function bmx_ecs_is_deferred:Int(worldPtr:Byte Ptr)

	Function bmx_ecs_add_pair(worldPtr:Byte Ptr, entityId:ULong, relationId:ULong, targetId:ULong)
	Function bmx_ecs_remove_pair(worldPtr:Byte Ptr, entityId:ULong, relationId:ULong, targetId:ULong)
	Function bmx_ecs_has_pair:Int(worldPtr:Byte Ptr, entityId:ULong, relationId:ULong, targetId:ULong)
	Function bmx_ecs_pair:ULong(relationId:ULong, targetId:ULong)
	Function bmx_ecs_get_target:ULong(worldPtr:Byte Ptr, entityId:ULong, relationId:ULong, index:Int)

	Function bmx_ecs_set_name(worldPtr:Byte Ptr, entityId:ULong, name:String)

	Function bmx_ecs_iter_count:Int(iterPtr:Byte Ptr)
	Function bmx_ecs_field_w_size(iterPtr:Byte Ptr, size:Size_T, index:Int, data:Byte Ptr Ptr)
	Function bmx_ecs_iter_entity:ULong(iterPtr:Byte Ptr, index:Int)
	Function bmx_ecs_iter_field_is_self:Int(iterPtr:Byte Ptr, index:Int)
	Function bmx_ecs_iter_delta_time:Float(iterPtr:Byte Ptr)
	Function bmx_ecs_iter_field_id:ULong(iterPtr:Byte Ptr, index:Int)
	Function bmx_ecs_iter_pair_first:ULong(iterPtr:Byte Ptr, index:Int)
	Function bmx_ecs_iter_pair_second:ULong(iterPtr:Byte Ptr, index:Int)
	Function bmx_ecs_iter_is_true:Int(iterPtr:Byte Ptr)
	Function bmx_ecs_iter_changed:Int(iterPtr:Byte Ptr)
	Function bmx_ecs_iter_skip(iterPtr:Byte Ptr)

	Function bmx_ecs_query_each(worldPtr:Byte Ptr, queryPtr:Byte Ptr)
	Function bmx_ecs_query_destroy(worldPtr:Byte Ptr, queryPtr:Byte Ptr)

	Function bmx_ecs_query_reset(queryPtr:Byte Ptr)
	Function bmx_ecs_query_current:Byte Ptr(queryPtr:Byte Ptr)
	Function bmx_ecs_query_advance:Int(queryPtr:Byte Ptr)
	Function bmx_ecs_query_reset_group(queryPtr:Byte Ptr, groupId:ULong)

	Function FlecsStatsImport(worldPtr:Byte Ptr)
	Function FlecsRestImport(worldPtr:Byte Ptr)

	Function bmx_ecs_enable_rest_server(worldPtr:Byte Ptr, port:Int)

	Function bmx_ecs_set_target_fps(worldPtr:Byte Ptr, fps:Float)

	Function bmx_ecs_register_observer:ULong(worldPtr:Byte Ptr, name:String, event:ULong, componentIds:ULong Ptr, componentCount:Int, observer:Object)
	Function bmx_ecs_register_struct_meta(worldPtr:Byte Ptr, componentId:ULong, fields:Byte Ptr, fieldCount:Int)

	Function bmx_ecs_new_prefab:ULong(worldPtr:Byte Ptr, name:String)
	Function bmx_ecs_instantiate:ULong(worldPtr:Byte Ptr, prefabId:ULong)
	Function bmx_ecs_set_on_instantiate(worldPtr:Byte Ptr, componentId:ULong, policyId:ULong)
	Function bmx_ecs_is_prefab:Int(worldPtr:Byte Ptr, entityId:ULong)

	Function bmx_ecs_entity_to_json:String(worldPtr:Byte Ptr, entityId:ULong)
	Function bmx_ecs_component_to_json:String(worldPtr:Byte Ptr, entityId:ULong, componentId:ULong)

	Function bmx_ecs_modified_component(worldPtr:Byte Ptr, entityId:ULong, componentId:ULong)

	Function bmx_ecs_lookup:ULong(worldPtr:Byte Ptr, name:String)
	Function bmx_ecs_get_name:String(worldPtr:Byte Ptr, entityId:ULong)
	Function bmx_ecs_get_path:String(worldPtr:Byte Ptr, entityId:ULong)
	Function bmx_ecs_lookup_child:ULong(worldPtr:Byte Ptr, parentId:ULong, name:String)
	Function bmx_ecs_get_path_from:String(worldPtr:Byte Ptr, parentId:ULong, childId:ULong)

	Function bmx_ecs_enable(worldPtr:Byte Ptr, entityId:ULong, enable:Int)
	Function bmx_ecs_is_enabled:Int(worldPtr:Byte Ptr, entityId:ULong)
	Function bmx_ecs_set_can_toggle(worldPtr:Byte Ptr, componentId:ULong)
	Function bmx_ecs_enable_component(worldPtr:Byte Ptr, entityId:ULong, componentId:ULong, enabled:Int)
	Function bmx_ecs_is_component_enabled:Int(worldPtr:Byte Ptr, entityId:ULong, componentId:ULong)
	
	Function bmx_ecs_set_system_interval(worldPtr:Byte Ptr, systemId:ULong, interval:Float)
	Function bmx_ecs_set_system_rate(worldPtr:Byte Ptr, systemId:ULong, rate:Int)
	Function bmx_ecs_set_system_rate_source(worldPtr:Byte Ptr, systemId:ULong, rate:Int, tickSource:ULong)
	Function bmx_ecs_new_timer:ULong(worldPtr:Byte Ptr, name:String, interval:Float)
	Function bmx_ecs_new_rate_filter:ULong(worldPtr:Byte Ptr, name:String, rate:Int, tickSource:ULong)

	Function bmx_ecs_clear_entity(worldPtr:Byte Ptr, entityId:ULong)
	Function bmx_ecs_clone_entity:ULong(worldPtr:Byte Ptr, entityId:ULong, copyValue:Int)
	Function bmx_ecs_delete_with(worldPtr:Byte Ptr, componentId:ULong)
	Function bmx_ecs_remove_all(worldPtr:Byte Ptr, componentId:ULong)

	Function bmx_ecs_doc_set_brief(worldPtr:Byte Ptr, entityId:ULong, text:String)
	Function bmx_ecs_doc_get_brief:String(worldPtr:Byte Ptr, entityId:ULong)
	Function bmx_ecs_doc_set_detail(worldPtr:Byte Ptr, entityId:ULong, text:String)
	Function bmx_ecs_doc_get_detail:String(worldPtr:Byte Ptr, entityId:ULong)
	Function bmx_ecs_doc_set_color(worldPtr:Byte Ptr, entityId:ULong, color:String)
	Function bmx_ecs_doc_get_color:String(worldPtr:Byte Ptr, entityId:ULong)
	Function bmx_ecs_doc_set_link(worldPtr:Byte Ptr, entityId:ULong, link:String)
	Function bmx_ecs_doc_get_link:String(worldPtr:Byte Ptr, entityId:ULong)
	
	Function bmx_ecs_set_alias(worldPtr:Byte Ptr, entityId:ULong, text:String)
	Function bmx_ecs_set_symbol(worldPtr:Byte Ptr, entityId:ULong, text:String)
	Function bmx_ecs_get_symbol:String(worldPtr:Byte Ptr, entityId:ULong)

	Function bmx_ecs_new_phase:ULong(worldPtr:Byte Ptr, name:String, dependsOn:ULong)
	Function bmx_ecs_set_system_phase(worldPtr:Byte Ptr, systemId:ULong, phase:ULong)

	Function bmx_ecs_new_pipeline:ULong(worldPtr:Byte Ptr, name:String, expr:String)
	Function bmx_ecs_set_pipeline(worldPtr:Byte Ptr, pipeline:ULong)
	Function bmx_ecs_get_pipeline:ULong(worldPtr:Byte Ptr)
	Function bmx_ecs_run_pipeline(worldPtr:Byte Ptr, pipeline:ULong, deltaTime:Float)

	Function bmx_ecs_enable_stats(worldPtr:Byte Ptr)
	Function bmx_ecs_get_stats:Int(worldPtr:Byte Ptr, stats:SEcsWorldStats Var)
End Extern

Const FLECS_HI_COMPONENT_ID:ULong = 256

' Consts - Marker entities for query encoding
Const EcsWildcard:ULong =                    FLECS_HI_COMPONENT_ID + 11
Const EcsAny:ULong =                         FLECS_HI_COMPONENT_ID + 12
Const EcsThis:ULong =                        FLECS_HI_COMPONENT_ID + 13
Const EcsVariable:ULong =                    FLECS_HI_COMPONENT_ID + 14

' Consts - Traits
Const EcsTransitive:ULong =                  FLECS_HI_COMPONENT_ID + 15
Const EcsReflexive:ULong =                   FLECS_HI_COMPONENT_ID + 16
Const EcsSymmetric:ULong =                   FLECS_HI_COMPONENT_ID + 17
Const EcsFinal:ULong =                       FLECS_HI_COMPONENT_ID + 18
Const EcsOnInstantiate:ULong =               FLECS_HI_COMPONENT_ID + 19
Const EcsOverride:ULong =                    FLECS_HI_COMPONENT_ID + 20
Const EcsInherit:ULong =                     FLECS_HI_COMPONENT_ID + 21
Const EcsDontInherit:ULong =                 FLECS_HI_COMPONENT_ID + 22
Const EcsPairIsTag:ULong =                   FLECS_HI_COMPONENT_ID + 23
Const EcsExclusive:ULong =                   FLECS_HI_COMPONENT_ID + 24
Const EcsAcyclic:ULong =                     FLECS_HI_COMPONENT_ID + 25
Const EcsTraversable:ULong =                 FLECS_HI_COMPONENT_ID + 26
Const EcsWith:ULong =                        FLECS_HI_COMPONENT_ID + 27
Const EcsOneOf:ULong =                       FLECS_HI_COMPONENT_ID + 28
Const EcsCanToggle:ULong =                   FLECS_HI_COMPONENT_ID + 29
Const EcsTrait:ULong =                       FLECS_HI_COMPONENT_ID + 30
Const EcsRelationship:ULong =                FLECS_HI_COMPONENT_ID + 31
Const EcsTarget:ULong =                      FLECS_HI_COMPONENT_ID + 32

' Consts - Builtin relationships
Const EcsChildOf:ULong =                     FLECS_HI_COMPONENT_ID + 33
Const EcsIsA:ULong =                         FLECS_HI_COMPONENT_ID + 34
Const EcsDependsOn:ULong =                   FLECS_HI_COMPONENT_ID + 35

' Consts - Identifier tags
Const EcsName:ULong =                        FLECS_HI_COMPONENT_ID + 36
Const EcsSymbol:ULong =                      FLECS_HI_COMPONENT_ID + 37
Const EcsAlias:ULong =                       FLECS_HI_COMPONENT_ID + 38

' Consts - Events
Const EcsOnAdd:ULong =                       FLECS_HI_COMPONENT_ID + 39
Const EcsOnRemove:ULong =                    FLECS_HI_COMPONENT_ID + 40
Const EcsOnSet:ULong =                       FLECS_HI_COMPONENT_ID + 41
Const EcsOnDelete:ULong =                    FLECS_HI_COMPONENT_ID + 43
Const EcsOnDeleteTarget:ULong =              FLECS_HI_COMPONENT_ID + 44
Const EcsOnTableCreate:ULong =               FLECS_HI_COMPONENT_ID + 45
Const EcsOnTableDelete:ULong =               FLECS_HI_COMPONENT_ID + 46

' Consts - Systems
Const EcsMonitor:ULong =                     FLECS_HI_COMPONENT_ID + 63
Const EcsEmpty:ULong =                       FLECS_HI_COMPONENT_ID + 64
Const EcsPipeline:ULong =                    FLECS_HI_COMPONENT_ID + 65
Const EcsOnStart:ULong =                     FLECS_HI_COMPONENT_ID + 66
Const EcsPreFrame:ULong =                    FLECS_HI_COMPONENT_ID + 67
Const EcsOnLoad:ULong =                      FLECS_HI_COMPONENT_ID + 68
Const EcsPostLoad:ULong =                    FLECS_HI_COMPONENT_ID + 69
Const EcsPreUpdate:ULong =                   FLECS_HI_COMPONENT_ID + 70
Const EcsOnUpdate:ULong =                    FLECS_HI_COMPONENT_ID + 71
Const EcsOnValidate:ULong =                  FLECS_HI_COMPONENT_ID + 72
Const EcsPostUpdate:ULong =                  FLECS_HI_COMPONENT_ID + 73
Const EcsPreStore:ULong =                    FLECS_HI_COMPONENT_ID + 74
Const EcsOnStore:ULong =                     FLECS_HI_COMPONENT_ID + 75
Const EcsPostFrame:ULong =                   FLECS_HI_COMPONENT_ID + 76
Const EcsPhase:ULong =                       FLECS_HI_COMPONENT_ID + 77

Rem
bbdoc: Query must match prefabs.
about: Can be combined with other query flags on a query to include prefabs in the result set.
End Rem
Const EcsQueryMatchPrefab:UInt =            1:UInt Shl 1
Rem
bbdoc: Query must match disabled entities.
about: Can be combined with other query flags on a query to include disabled entities in the result set.
End Rem
Const EcsQueryMatchDisabled:UInt =          1:UInt Shl 2
Rem
bbdoc: Query must match empty tables.
about: Can be combined with other query flags on a query to include empty tables in the result set.
End Rem
Const EcsQueryMatchEmptyTables:UInt =       1:UInt Shl 3
Rem
bbdoc: Query may have unresolved entity identifiers.
about: Can be combined with other query flags on a query to allow unresolved entity identifiers in the result set.
End Rem
Const EcsQueryAllowUnresolvedByName:UInt =  1:UInt Shl 6
Rem
bbdoc: Query only returns whole tables (ignores toggle or member fields).
about: Can be combined with other query flags on a query to only return whole tables (ignores toggle or member fields).
End Rem
Const EcsQueryTableOnly:UInt =              1:UInt Shl 7
Rem
bbdoc: Enable change detection for a query.
about: Can be combined with other query flags on a query to enable change detection for a query.

Adding this flag makes it possible to use ecs_query_changed() and ecs_iter_changed() with the query. Change detection requires the query to be
cached. If cache_kind is left to the default value, this flag will cause it to default to #EcsQueryCacheAuto.
End Rem
Const EcsQueryDetectChanges:UInt =          1:UInt Shl 8
Rem
bbdoc: Enable ordering for query groups.
about: When this flag is set, groups will be iterated in ascending order, with lower group ids first and higher group ids afterwards.

This flag is enabled automatically when a query contains cascade terms.
End Rem
Const EcsQueryGroupByOrdered:UInt =         1:UInt Shl 9
Rem
bbdoc: Enable descending ordering for query groups.
about: When this flag is set in combination with EcsQueryGroupByOrdered, groups will
be iterated in descending order, with higher group ids first and lower group ids afterwards.

This flag is enabled automatically when a query contains cascade|desc terms.
End Rem
Const EcsQueryGroupByDesc:UInt =            1:UInt Shl 10


Rem
bbdoc: Match on self.
about: Can be combined with other term flags on #SEcsTerm.
End Rem
Const EcsSelf:ULong = 1:ULong Shl 63
Rem
bbdoc: Match by traversing upwards.
about: Can be combined with other term flags on #SEcsTerm.
End Rem
Const EcsUp:ULong = 1:ULong Shl 62
Rem
bbdoc: Traverse relationship transitively.
about: Can be combined with other term flags on #SEcsTerm.
End Rem
Const EcsTrav:ULong = 1:ULong Shl 61
Rem
bbdoc: Sort results breadth-first.
about: Can be combined with other term flags on #SEcsTerm.
End Rem
Const EcsCascade:ULong = 1:ULong Shl 60
Rem
bbdoc: Iterate groups in descending order.
about: Can be combined with other term flags on #SEcsTerm.
End Rem
Const EcsDesc:ULong = 1:ULong Shl 59
Rem
bbdoc: Term ID is a variable.
about: Can be combined with other term flags on #SEcsTerm.
End Rem
Const EcsIsVariable:ULong = 1:ULong Shl 58
Rem
bbdoc: Term ID is an entity.
about: Can be combined with other term flags on #SEcsTerm.
End Rem
Const EcsIsEntity:ULong = 1:ULong Shl 57
Rem
bbdoc: Term ID is a name (don't attempt to look up as an entity).
about: Can be combined with other term flags on #SEcsTerm.
End Rem
Const EcsIsName:ULong = 1:ULong Shl 56


Rem
bbdoc: All term traversal flags.
about: Can be combined with other term flags on #SEcsTerm.
End Rem
Const EcsTraverseFlags:ULong = EcsSelf | EcsUp | EcsTrav | EcsCascade | EcsDesc
Rem
bbdoc: All term reference kind flags.
about: Can be combined with other term flags on #SEcsTerm.
End Rem
Const EcsTermRefFlags:ULong = EcsTraverseFlags | EcsIsVariable | EcsIsEntity | EcsIsName



Enum EEscPrimitiveKind
	None = 0
	EcsBool = 1
    EcsChar
    EcsByte
    EcsU8
    EcsU16
    EcsU32
    EcsU64
    EcsI8
    EcsI16
    EcsI32
    EcsI64
    EcsF32
    EcsF64
    EcsUPtr
    EcsIPtr
    EcsString
    EcsEntity
    EcsId
End Enum

Enum EEcsOperKind
	EcsAnd
	EcsOr
	EcsNot
	EcsOptional
	EcsAndFrom
	EcsOrFrom
	EcsNotFrom
End Enum

Enum EEcsInoutKind
	EcsInOutDefault
	EcsInOutNone
	EcsInOutFilter
	EcsInOut
	EcsIn
	EcsOut
End Enum

Rem
bbdoc: Specifies how a query caches its results.
about:
Queries can be created with a "cache kind", which specifies the caching behaviour for a query. There are four different caching kinds:

| Kind	   | Description                        |
|----------|------------------------------------|
| EcsQueryCacheDefault | The default caching behaviour. Behaviour is determined by query creation context. |
| EcsQueryCacheAuto | Caches query terms that are cacheable. |
| EcsQueryCacheAll | Requires that all query terms are cached. |
| EcsQueryCacheNone | No caching. |

End Rem
Enum EEcsQueryCacheKind
	EcsQueryCacheDefault
    EcsQueryCacheAuto
    EcsQueryCacheAll
    EcsQueryCacheNone
End Enum

Struct SEcsMetaField
	Field name:String
	Field kind:EEscPrimitiveKind
	Field offset:Size_T
	Field structId:ULong

	Method New(name:String, kind:EEscPrimitiveKind, offset:Size_T, structId:ULong = 0)
		Self.name = name
		Self.kind = kind
		Self.structId = structId
		Self.offset = offset
	End Method

End Struct

Rem
bbdoc: A component is a type of data that can be attached to an entity.
about: Components are the building blocks of entities. They define the data that an entity can hold.
Components can be simple data types, such as integers or floats, or they can be more complex data structures, such as structs or classes.
Components can also be used to define relationships between entities.
End Rem
Struct SEcsComponent
	Field id:ULong
	Field size:Size_T
End Struct

Rem
bbdoc: A term is a single condition in a query.
about: It can be a component, a pair, or a variable.
A term can be combined with other terms to form a query.
Terms can also have flags that modify their behaviour.
End Rem
Struct SEcsTerm

	Field id:ULong
	Field oper:EEcsOperKind
	Field inout:EEcsInoutKind
	Field src:ULong      ' 0 = default/self
	Field trav:ULong

	Method New(id:ULong, oper:EEcsOperKind = EEcsOperKind.EcsAnd, inout:EEcsInoutKind = EEcsInoutKind.EcsInOutDefault, src:ULong = EcsThis, trav:ULong = 0)
		Self.id = id
		Self.oper = oper
		Self.inout = inout
		Self.src = src
		Self.trav = trav
	End Method

	Rem
	bbdoc: Creates a new term with the specified component ID.
	End Rem
	Function With:SEcsTerm(id:ULong)
		Return New SEcsTerm(id)
	End Function

	Rem
	bbdoc: Creates a new term with the specified component.
	End Rem
	Function With:SEcsTerm(component:SEcsComponent)
		Return New SEcsTerm(component.id)
	End Function

	Rem
	bbdoc: Creates a new term with the specified pair of @relation and @target component ids.
	End Rem
	Function Pair:SEcsTerm(relation:ULong, target:ULong)
		Return New SEcsTerm(bmx_ecs_pair(relation, target))
	End Function

	Rem
	bbdoc: Creates a new term with the specified pair of @relation and @target components.
	End Rem
	Function Pair:SEcsTerm(relation:SEcsComponent, target:ULong)
		Return Pair(relation.id, target)
	End Function

	Rem
	bbdoc: Creates a new term with the specified pair of @relation and @target components.
	End Rem
	Function Pair:SEcsTerm(relation:ULong, target:SEcsComponent)
		Return Pair(relation, target.id)
	End Function

	Rem
	bbdoc: Creates a new term with the specified pair of @relation and @target components.
	End Rem
	Function Pair:SEcsTerm(relation:SEcsComponent, target:SEcsComponent)
		Return Pair(relation.id, target.id)
	End Function

	Rem
	bbdoc: Applies the "optional" operator to the term.
	about: The Optional operator optionally matches with a component.
	While this operator does not affect the entities that are matched by a query, it can provide more efficient access to a component
	when compared to conditionally getting the component in user code.
	End Rem
	Method Optional:SEcsTerm()
        oper = EEcsOperKind.EcsOptional
        Return Self
    End Method

	Rem
	bbdoc: Applies the "not" operator to the term.
	about: The Not operator makes it possible to exclude entities with a specified component.
	Fields for terms that uses the Not operator will never provide data.
	End Rem
	Method Without:SEcsTerm()
		oper = EEcsOperKind.EcsNot
		Return Self
	End Method

	Rem
	bbdoc: Applies the "in" access modifier to the term, marking it as read-only.
	about: When using pipelines, the scheduler may use access modifiers to determine where sync points are inserted.
	This typically happens when a system access modifier indicates a system writing to a component not matched
	by the query (for example, by using `set`), and is followed by a system that reads that component.

	Access modifiers may also be used by serializers that serialize the output of an iterator.
	A serializer may for example decide to not serialize component values that have the Out or None modifiers.
	End Rem
	Method AsReadOnly:SEcsTerm()
		inout = EEcsInoutKind.EcsIn
		Return Self
	End Method

	Rem
	bbdoc: Applies the "out" access modifier to the term, marking it as write-only.
	about: When using pipelines, the scheduler may use access modifiers to determine where sync points are inserted.
	This typically happens when a system access modifier indicates a system reading from a component not matched
	by the query (for example, by using `get`), and is followed by a system that writes to that component.

	Access modifiers may also be used by serializers that serialize the output of an iterator.
	A serializer may for example decide to not serialize component values that have the In or None modifiers.
	End Rem
	Method AsWriteOnly:SEcsTerm()
		inout = EEcsInoutKind.EcsOut
		Return Self
	End Method

	Rem
	bbdoc: Applies the "inout" access modifier to the term, marking it as both read and write.
	about: When using pipelines, the scheduler may use access modifiers to determine where sync points are inserted.
	This typically happens when a system access modifier indicates a system reading from a component not matched
	by the query (for example, by using `get`), and is followed by a system that writes to that component.

	Access modifiers may also be used by serializers that serialize the output of an iterator.
	A serializer may for example decide to not serialize component values that have the In or None modifiers.
	End Rem
	Method AsReadWrite:SEcsTerm()
		inout = EEcsInoutKind.EcsInOut
		Return Self
	End Method

	Rem
	bbdoc: Applies the "inout none" access modifier to the term, marking it as neither read nor write.
	about: When using pipelines, the scheduler may use access modifiers to determine where sync points are inserted.
	This typically happens when a system access modifier indicates a system reading from a component not matched
	by the query (for example, by using `get`), and is followed by a system that writes to that component.

	Access modifiers may also be used by serializers that serialize the output of an iterator.
	A serializer may for example decide to not serialize component values that have the In or None modifiers.
	End Rem
	Method None:SEcsTerm()
		inout = EEcsInoutKind.EcsInOutNone
		Return Self
	End Method

	Rem
	bbdoc: The term is matched against a specific source entity.
	End Rem
    Method From:SEcsTerm(src:ULong)
        Self.src = src
        Return Self
    End Method

	Rem
	bbdoc: Customizes traversal behaviour by matching on `Up`.
	about: If just `This` is set a query will only match components on the matched entity (no traversal).
	If just `Up` is set, a query will only match components that can be reached by following the relationship and ignore components from the matched entity.
	If both `This` and `Up` are set, the query will first look on the matched entity, and if it does not have the component the query will
	continue searching by traverse the relationship.

	When an Up traversal flag is set, but no traversal relationship is provided, the traversal relationship defaults to ChildOf.

	Note: In the BlitzMax binding of flecs, we refer to `This` here instead of `Self` to avoid conflicts with the `Self` keyword.
	End Rem
	Method Up:SEcsTerm(relation:ULong = EcsIsA)
		src :| EcsUp
		trav = relation
		Return Self
	End Method

	Rem
	bbdoc: Customizes traversal behaviour by matching on `Cascade`, which is the same as `Up` while also iterating in breadth-first order.
	about: If just `This` is set a query will only match components on the matched entity (no traversal).
	If just `Cascade` is set, a query will only match components that can be reached by following the relationship and ignore components from the matched entity.
	If both `This` and `Cascade` are set, the query will first look on the matched entity, and if it does not have the component the query will
	continue searching by traverse the relationship.

	When a Cascade traversal flag is set, but no traversal relationship is provided, the traversal relationship defaults to ChildOf.

	Note: In the BlitzMax binding of flecs, we refer to `This` here instead of `Self` to avoid conflicts with the `Self` keyword.
	End Rem
	Method Cascade:SEcsTerm(relation:ULong = EcsChildOf)
		src :| EcsCascade
		trav = relation
		Return Self
	End Method

	Rem
	bbdoc: Customizes traversal behaviour by matching on `This`.
	about: If just `This` is set a query will only match components on the matched entity (no traversal).
	If just `Up` is set, a query will only match components that can be reached by following the relationship and ignore components from the matched entity.
	If both `This` and `Up` are set, the query will first look on the matched entity, and if it does not have the component the query will
	continue searching by traverse the relationship.

	When an Up traversal flag is set, but no traversal relationship is provided, the traversal relationship defaults to ChildOf.

	Note: In the BlitzMax binding of flecs, we refer to `This` here instead of `Self` to avoid conflicts with the `Self` keyword.
	End Rem
	Method This:SEcsTerm()
		src :| EcsSelf
		trav = 0
		Return Self
	End Method

	Rem
	bbdoc: Customizes traversal behaviour by reversing the order of traversal, which is the same as `Up` while also iterating in descending order.
	about: For example combining with `Cascade` to iterate hierarchy bottom to top.
	End Rem
	Method Desc:SEcsTerm()
		src :| EcsDesc
		Return Self
	End Method

	Rem
	bbdoc: Applies the "or" operator to the term.
	about: The Or operator allows for matching a single component from a list.
	Using the Or operator means that a single term can return results of multiple types. When the value of a component is used while
	iterating the results of an Or operator, an application has to make sure that it is working with the expected type.

	When using the Or operator, the terms participating in the Or expression are made available as a single field.
	Field indices obtained from an iterator need to account for this.

	Consider the following query:
	```
	Position, Velocity || Speed, Mass
	```
	
	This query has 4 terms, while an iterator for the query returns results with 3 fields.
	This is important to consider when retrieving the field for a term, as its index has to be adjusted.
	In this example, `Position` has index 1, `Velocity || Speed` has index 2, and `Mass` has index 3.
	End Rem
	Method Any:SEcsTerm()
		oper = EEcsOperKind.EcsOr
		Return Self
	End Method

	Method SelfOnly:SEcsTerm()
		src = EcsThis | EcsSelf
		trav = 0
		Return Self
	End Method

	Method SelfOrUp:SEcsTerm(relation:ULong = EcsIsA)
		src = EcsThis | EcsSelf | EcsUp
		trav = relation
		Return Self
	End Method

End Struct

Struct SEcsWorldStats

	Field entityCount:Long
	Field tableCount:Long

	Field componentCount:Int
	Field tagCount:Int
	Field pairCount:Int

End Struct
