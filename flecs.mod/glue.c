/*
  Copyright (c) 2026 Bruce A Henderson
 
  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:
  
  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.
  
  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  THE SOFTWARE.
*/ 
#include "flecs.h"
#include "brl.mod/blitz.mod/blitz.h"

extern void ecs_flecs_TEcsSystem__Invoke(BBObject *systemObj, ecs_iter_t *it);
extern void ecs_flecs_TEcsQuery__Invoke(BBObject *queryObj, ecs_iter_t *it);
extern void ecs_flecs_TEcsObserver__Invoke(BBObject *observerObj, ecs_iter_t *it);
extern int ecs_flecs_TEcsOrderedQuery__Compare(BBObject *queryObj, ecs_entity_t e1, const void *ptr1, ecs_entity_t e2, const void *ptr2);

typedef struct bmx_ecs_query_t {
    ecs_query_t *query;
    ecs_iter_t iter;
} bmx_ecs_query_t;

typedef struct bmx_ecs_meta_field_t {
    BBString *name;
    ecs_primitive_kind_t kind;
    size_t offset;
    BBULONG structId;
} bmx_ecs_meta_field_t;

typedef struct bmx_ecs_term_t {
    BBULONG id;
    int oper;
    int inout;
    BBULONG src;
    BBULONG trav;
} bmx_ecs_term_t;

typedef struct bmx_ecs_world_stats_t {
    int64_t entityCount;
    int64_t tableCount;

    int componentCount;
    int tagCount;
    int pairCount;
} bmx_ecs_world_stats_t;

static void bmx_ecs_system_callback(ecs_iter_t *it) {
    BBObject *systemObj = (BBObject*)it->callback_ctx;
    ecs_flecs_TEcsSystem__Invoke(systemObj, it);
}

static void bmx_ecs_query_callback(ecs_iter_t *it) {
    BBObject *queryObj = (BBObject*)it->callback_ctx;
    ecs_flecs_TEcsQuery__Invoke(queryObj, it);
}

static void bmx_ecs_observer_callback(ecs_iter_t *it) {
    BBObject *observer = (BBObject *)it->callback_ctx;
    ecs_flecs_TEcsObserver__Invoke(observer, it);
}

BBULONG bmx_ecs_register_component(ecs_world_t * world, BBString * name, size_t size, size_t alignment) {

    char * n = (char*)bbStringToUTF8String(name);

    ecs_component_desc_t desc = {0};
    ecs_entity_desc_t edesc = {0};
    edesc.name = n;
    edesc.symbol = n;

    desc.entity = ecs_entity_init(world, &edesc);
    desc.type.size = size;
    desc.type.alignment = alignment;
   
    ecs_entity_t id = ecs_component_init(world, &desc);

    bbMemFree(n);

    return id;
}

BBULONG bmx_ecs_register_system(ecs_world_t *world, BBString *name, BBULONG phase, BBULONG *component_ids, int32_t component_count, BBObject * systemObj) {

    if (component_count > FLECS_TERM_COUNT_MAX) {
        return 0;
    }

    char *n = (char*)bbStringToUTF8String(name);

    ecs_system_desc_t desc = {0};

    ecs_entity_desc_t edesc = {0};
    edesc.name = n;

    ecs_entity_t system_entity = ecs_entity_init(world, &edesc);

    ecs_add_id(world, system_entity, ecs_pair(EcsDependsOn, (ecs_entity_t)phase));
    ecs_add_id(world, system_entity, (ecs_id_t)phase);

    desc.entity = system_entity;

    for (int32_t i = 0; i < component_count; i++) {
        desc.query.terms[i].id = (ecs_id_t)component_ids[i];
    }

    desc.callback = bmx_ecs_system_callback;
    desc.callback_ctx = systemObj;

    ecs_entity_t system = ecs_system_init(world, &desc);

    bbMemFree(n);

    return (BBULONG)system;
}

BBULONG bmx_ecs_register_system_terms(ecs_world_t *world, BBString *name, BBULONG phase, bmx_ecs_term_t *terms, int32_t term_count, BBObject * systemObj) {
    
    if (term_count > FLECS_TERM_COUNT_MAX) {
        return 0;
    }

    char *n = (char*)bbStringToUTF8String(name);

    ecs_system_desc_t desc = {0};

    ecs_entity_desc_t edesc = {0};
    edesc.name = n;

    ecs_entity_t system_entity = ecs_entity_init(world, &edesc);

    ecs_add_id(world, system_entity, ecs_pair(EcsDependsOn, (ecs_entity_t)phase));
    ecs_add_id(world, system_entity, (ecs_id_t)phase);

    desc.entity = system_entity;

    for (int32_t i = 0; i < term_count; i++) {
        desc.query.terms[i].id = (ecs_id_t)terms[i].id;
        desc.query.terms[i].oper = terms[i].oper;
        desc.query.terms[i].inout = terms[i].inout;
        desc.query.terms[i].src.id = (ecs_id_t)terms[i].src;
        desc.query.terms[i].trav = (ecs_id_t)terms[i].trav;
    }

    desc.callback = bmx_ecs_system_callback;
    desc.callback_ctx = systemObj;

    ecs_entity_t system = ecs_system_init(world, &desc);

    bbMemFree(n);

    return (BBULONG)system;
}


void bmx_ecs_set_component(ecs_world_t *world, BBULONG entityId, BBULONG componentId, size_t size, void *data) {
    ecs_set_id(world, (ecs_entity_t)entityId, (ecs_id_t)componentId, size, data);
}

int bmx_ecs_progress(ecs_world_t *world, float deltaTime) {
    return (int)ecs_progress(world, deltaTime);
}

void bmx_ecs_run(ecs_world_t *world, BBULONG systemId, float deltaTime) {
    ecs_run(world, (ecs_entity_t)systemId, deltaTime, NULL);
}

int bmx_ecs_get_component(ecs_world_t *world, BBULONG entityId, BBULONG componentId, void **data) {
    *data = NULL;

    ecs_entity_t e = (ecs_entity_t)entityId;

    if (!ecs_is_alive(world, e)) {
        return 0;
    }

    void *ptr = ecs_get_id(world, (ecs_entity_t)entityId, (ecs_id_t)componentId);

    if (!ptr) {
        return 0;
    }

    *data = ptr;
    return 1;
}

int bmx_ecs_has_component(ecs_world_t *world, BBULONG entityId, BBULONG componentId) {
    ecs_entity_t e = (ecs_entity_t)entityId;

    if (!ecs_is_alive(world, e)) {
        return 0;
    }

    return ecs_has_id(world, (ecs_entity_t)entityId, (ecs_id_t)componentId);
}

void bmx_ecs_remove_component(ecs_world_t *world, BBULONG entityId, BBULONG componentId) {
    ecs_remove_id(world, (ecs_entity_t)entityId, (ecs_id_t)componentId);
}

void bmx_ecs_delete_entity(ecs_world_t *world, BBULONG entityId) {
    ecs_entity_t e = (ecs_entity_t)entityId;

    if (!ecs_is_alive(world, e)) {
        return;
    }

    ecs_delete(world, e);
}

int bmx_ecs_is_alive(ecs_world_t *world, BBULONG entityId) {
    return (int)ecs_is_alive(world, (ecs_entity_t)entityId);
}

void bmx_ecs_add_component(ecs_world_t *world, BBULONG entityId, BBULONG componentId) {
    ecs_add_id(world, (ecs_entity_t)entityId, (ecs_id_t)componentId);
}

bmx_ecs_query_t *bmx_ecs_query_create(ecs_world_t *world, BBULONG *componentIds, int32_t componentCount, BBObject *queryObj, uint32_t flags, int cacheKind) {
    if (componentCount > FLECS_TERM_COUNT_MAX) {
        return NULL;
    }

    ecs_query_desc_t desc = {0};
    desc.flags = (ecs_flags32_t)flags;
    desc.cache_kind = (ecs_query_cache_kind_t)cacheKind;

    for (int32_t i = 0; i < componentCount; i++) {
        desc.terms[i].id = (ecs_id_t)componentIds[i];
    }

    desc.ctx = queryObj;

    bmx_ecs_query_t *query = (bmx_ecs_query_t*)malloc(sizeof(bmx_ecs_query_t));

    query->query = ecs_query_init(world, &desc);

    return query;
}

bmx_ecs_query_t *bmx_ecs_ordered_query_create(ecs_world_t *world, BBULONG *componentIds, int32_t componentCount, BBULONG orderById, ecs_order_by_action_t *callback, BBObject *queryObj, uint32_t flags, int cacheKind) {
    if (componentCount > FLECS_TERM_COUNT_MAX) {
        return NULL;
    }

    ecs_query_desc_t desc = {0};
    desc.flags = (ecs_flags32_t)flags;
    desc.cache_kind = (ecs_query_cache_kind_t)cacheKind;

    for (int32_t i = 0; i < componentCount; i++) {
        desc.terms[i].id = (ecs_id_t)componentIds[i];
    }

    desc.order_by = (ecs_id_t)orderById;
    desc.order_by_callback = callback;
    desc.ctx = queryObj;

    bmx_ecs_query_t *query = (bmx_ecs_query_t*)malloc(sizeof(bmx_ecs_query_t));

    query->query = ecs_query_init(world, &desc);

    return query;
}

bmx_ecs_query_t *bmx_ecs_query_create_terms(ecs_world_t *world, bmx_ecs_term_t *terms, int32_t termCount, BBObject *queryObj, uint32_t flags, int cacheKind) {
    if (termCount > FLECS_TERM_COUNT_MAX) {
        return NULL;
    }

    ecs_query_desc_t desc = {0};
    desc.flags = (ecs_flags32_t)flags;
    desc.cache_kind = (ecs_query_cache_kind_t)cacheKind;

    for (int32_t i = 0; i < termCount; i++) {
        desc.terms[i].id = (ecs_id_t)terms[i].id;
        desc.terms[i].oper = terms[i].oper;
        desc.terms[i].inout = terms[i].inout;
        desc.terms[i].src.id = (ecs_id_t)terms[i].src;
        desc.terms[i].trav = (ecs_id_t)terms[i].trav;
    }

    desc.ctx = queryObj;

    bmx_ecs_query_t *query = (bmx_ecs_query_t*)malloc(sizeof(bmx_ecs_query_t));

    query->query = ecs_query_init(world, &desc);

    return query;
}

bmx_ecs_query_t *bmx_ecs_grouped_query_create_terms(ecs_world_t *world, bmx_ecs_term_t *terms, int32_t termCount, BBULONG groupById, BBObject *queryObj, uint32_t flags, int cacheKind) {
    if (termCount > FLECS_TERM_COUNT_MAX) {
        return NULL;
    }

    ecs_query_desc_t desc = {0};
    desc.flags = (ecs_flags32_t)flags;
    desc.cache_kind = (ecs_query_cache_kind_t)cacheKind;

    for (int32_t i = 0; i < termCount; i++) {
        desc.terms[i].id = (ecs_id_t)terms[i].id;
        desc.terms[i].oper = terms[i].oper;
        desc.terms[i].inout = terms[i].inout;
        desc.terms[i].src.id = (ecs_id_t)terms[i].src;
        desc.terms[i].trav = (ecs_id_t)terms[i].trav;
    }

    desc.group_by = (ecs_id_t)groupById;
    desc.ctx = queryObj;

    bmx_ecs_query_t *query = (bmx_ecs_query_t*)malloc(sizeof(bmx_ecs_query_t));

    query->query = ecs_query_init(world, &desc);

    return query;
}

bmx_ecs_query_t *bmx_ecs_ordered_query_create_terms(ecs_world_t *world, bmx_ecs_term_t *terms, int32_t termCount, BBULONG orderById, ecs_order_by_action_t *callback, BBObject *queryObj, uint32_t flags, int cacheKind) {
    if (termCount > FLECS_TERM_COUNT_MAX) {
        return NULL;
    }

    ecs_query_desc_t desc = {0};
    desc.flags = (ecs_flags32_t)flags;
    desc.cache_kind = (ecs_query_cache_kind_t)cacheKind;

    for (int32_t i = 0; i < termCount; i++) {
        desc.terms[i].id = (ecs_id_t)terms[i].id;
        desc.terms[i].oper = terms[i].oper;
        desc.terms[i].inout = terms[i].inout;
        desc.terms[i].src.id = (ecs_id_t)terms[i].src;
        desc.terms[i].trav = (ecs_id_t)terms[i].trav;
    }

    desc.order_by = (ecs_id_t)orderById;
    desc.order_by_callback = callback;
    desc.ctx = queryObj;

    bmx_ecs_query_t *query = (bmx_ecs_query_t*)malloc(sizeof(bmx_ecs_query_t));

    query->query = ecs_query_init(world, &desc);

    return query;
}

bmx_ecs_query_t *bmx_ecs_grouped_ordered_query_create_terms(ecs_world_t *world, bmx_ecs_term_t *terms, int32_t termCount, BBULONG groupById, BBULONG orderById, ecs_order_by_action_t *callback, BBObject *queryObj, uint32_t flags, int cacheKind) {
    if (termCount > FLECS_TERM_COUNT_MAX) {
        return NULL;
    }

    ecs_query_desc_t desc = {0};
    desc.flags = (ecs_flags32_t)flags;
    desc.cache_kind = (ecs_query_cache_kind_t)cacheKind;

    for (int32_t i = 0; i < termCount; i++) {
        desc.terms[i].id = (ecs_id_t)terms[i].id;
        desc.terms[i].oper = terms[i].oper;
        desc.terms[i].inout = terms[i].inout;
        desc.terms[i].src.id = (ecs_id_t)terms[i].src;
        desc.terms[i].trav = (ecs_id_t)terms[i].trav;
    }

    desc.group_by = (ecs_id_t)groupById;
    desc.order_by = (ecs_id_t)orderById;
    desc.order_by_callback = callback;
    desc.ctx = queryObj;

    bmx_ecs_query_t *query = (bmx_ecs_query_t*)malloc(sizeof(bmx_ecs_query_t));

    query->query = ecs_query_init(world, &desc);

    return query;
}

int bmx_ecs_defer_begin(ecs_world_t *world) {
    return ecs_defer_begin(world);
}

int bmx_ecs_defer_end(ecs_world_t *world) {
    return (int)ecs_defer_end(world);
}

int bmx_ecs_is_deferred(ecs_world_t *world) {
    return (int)ecs_is_deferred(world);
}

void bmx_ecs_add_pair(ecs_world_t *world, BBULONG entity, BBULONG relation, BBULONG target) {
    ecs_add_id( world, (ecs_entity_t)entity, ecs_pair((ecs_entity_t)relation, (ecs_entity_t)target));
}

int bmx_ecs_has_pair(ecs_world_t *world, BBULONG entity, BBULONG relation, BBULONG target) {

    ecs_entity_t e = (ecs_entity_t)entity;

    if (!ecs_is_alive(world, e)) {
        return 0;
    }

    return (int)ecs_has_id(world, e, ecs_pair((ecs_entity_t)relation, (ecs_entity_t)target));
}

void bmx_ecs_remove_pair(ecs_world_t *world, BBULONG entity, BBULONG relation, BBULONG target) {

    ecs_entity_t e = (ecs_entity_t)entity;

    if (!ecs_is_alive(world, e)) {
        return;
    }

    ecs_remove_id(world, e, ecs_pair((ecs_entity_t)relation, (ecs_entity_t)target));
}

BBULONG bmx_ecs_pair(BBULONG relation, BBULONG target) {
    return (BBULONG)ecs_pair((ecs_entity_t)relation, (ecs_entity_t)target);
}

BBULONG bmx_ecs_get_target(ecs_world_t *world, BBULONG entity, BBULONG relation, int32_t index) {
    return (BBULONG)ecs_get_target(world, (ecs_entity_t)entity, (ecs_entity_t)relation, index);
}

void bmx_ecs_set_name(ecs_world_t *world, BBULONG entity, BBString *name) {

    ecs_entity_t e = (ecs_entity_t)entity;

    if (!ecs_is_alive(world, e)) {
        return;
    }

    char *n = bbStringToCString(name);
    ecs_set_name(world, e, n);
    bbMemFree(n);
}

BBULONG bmx_ecs_new_entity(ecs_world_t *world, BBString *name) {

    ecs_entity_desc_t desc = {0};

    if (name != &bbEmptyString) {
        char *n = bbStringToCString(name);

        desc.name = n;

        ecs_entity_t e = ecs_entity_init(world, &desc);

        bbMemFree(n);

        return (BBULONG)e;
    }

    return (BBULONG)ecs_new(world);
}

BBULONG bmx_ecs_register_observer(ecs_world_t *world, BBString *name, BBULONG event, BBULONG *component_ids, int32_t component_count, BBObject *observerObj) {

    char *n = bbStringToCString(name);

    ecs_observer_desc_t desc = {0};
    
    ecs_entity_desc_t edesc = {0};
    edesc.name = n;

    desc.entity = ecs_entity_init(world, &edesc);

    for (int32_t i = 0; i < component_count; ++i) {
        desc.query.terms[i].id = (ecs_id_t)component_ids[i];
    }

    desc.events[0] = (ecs_entity_t)event;

    desc.callback = bmx_ecs_observer_callback;
    desc.callback_ctx = observerObj;

    ecs_entity_t id = ecs_observer_init(world, &desc);

    bbMemFree(n);

    return (BBULONG)id;
}

static ecs_entity_t bmx_ecs_primitive_type(ecs_primitive_kind_t kind) {
    switch (kind) {
        case EcsBool: return ecs_id(ecs_bool_t);
        case EcsChar: return ecs_id(ecs_char_t);
        case EcsByte: return ecs_id(ecs_byte_t);
        case EcsU8: return ecs_id(ecs_u8_t);
        case EcsU16: return ecs_id(ecs_u16_t);
        case EcsU32: return ecs_id(ecs_u32_t);
        case EcsU64: return ecs_id(ecs_u64_t);
        case EcsI8: return ecs_id(ecs_i8_t);
        case EcsI16: return ecs_id(ecs_i16_t);
        case EcsI32: return ecs_id(ecs_i32_t);
        case EcsI64: return ecs_id(ecs_i64_t);
        case EcsF32: return ecs_id(ecs_f32_t);
        case EcsF64: return ecs_id(ecs_f64_t);
        case EcsString: return ecs_id(ecs_string_t);
        default: return 0;
    }
}

void bmx_ecs_register_struct_meta(ecs_world_t *world, BBULONG componentId, bmx_ecs_meta_field_t *fields, int fieldCount) {

    if (fieldCount > ECS_MEMBER_DESC_CACHE_SIZE) {
        return;
    }

    ecs_struct_desc_t desc = {0};

    desc.entity = (ecs_entity_t)componentId;

    for (int i = 0; i < fieldCount; ++i) {

        char *n = (char*)bbStringToUTF8String(fields[i].name);

        desc.members[i].name = n;
        desc.members[i].type = bmx_ecs_primitive_type(fields[i].kind);
        desc.members[i].offset = fields[i].offset;
    }

    ecs_struct_init(world, &desc);

    for (int i = 0; i < fieldCount; ++i) {
        bbMemFree((void *)desc.members[i].name);
    }
}

BBULONG bmx_ecs_new_prefab(ecs_world_t *world, BBString *name) {

    char *n = (char*)bbStringToUTF8String(name);

    ecs_entity_desc_t desc = {0};
    desc.add = ecs_ids( EcsPrefab );
    desc.name = n;

    ecs_entity_t prefab = ecs_entity_init(world, &desc);

    bbMemFree(n);

    return (BBULONG)prefab;
}

BBULONG bmx_ecs_instantiate(ecs_world_t *world, BBULONG prefab) {
    return (BBULONG)ecs_new_w_pair(world, EcsIsA, (ecs_entity_t)prefab);
}

void bmx_ecs_set_on_instantiate(ecs_world_t *world, BBULONG component_id, BBULONG policy) {
    ecs_add_id(world, (ecs_entity_t)component_id, ecs_pair(EcsOnInstantiate, (ecs_entity_t)policy));
}

int bmx_ecs_is_prefab(ecs_world_t *world, BBULONG entity) {
    return (int)ecs_has_id(world, (ecs_entity_t)entity, EcsPrefab);
}

BBString * bmx_ecs_entity_to_json(ecs_world_t *world, BBULONG entityId) {
    ecs_entity_t e = (ecs_entity_t)entityId;

    if (!ecs_is_alive(world, e)) {
        return &bbEmptyString;
    }

    ecs_entity_to_json_desc_t desc = {0};
    desc.serialize_entity_id = true;
    desc.serialize_doc = true;
    desc.serialize_full_paths = true;
    desc.serialize_values = true;

    char *json = ecs_entity_to_json(world, (ecs_entity_t)entityId, &desc);

    if (!json) {
        return &bbEmptyString;
    }

    BBString *result = bbStringFromUTF8String(json);
    
    ecs_os_free(json);

    return result;
}

BBString * bmx_ecs_component_to_json(ecs_world_t *world, BBULONG entityId, BBULONG componentId) {
    ecs_entity_t e = (ecs_entity_t)entityId;

    if (!ecs_is_alive(world, e)) {
        return &bbEmptyString;
    }

    void *ptr = ecs_get_id(world, entityId, (ecs_id_t)componentId);

    char *json = ecs_ptr_to_json(world, (ecs_entity_t)componentId, ptr);

    if (!json) {
        return &bbEmptyString;
    }

    BBString *result = bbStringFromUTF8String(json);
    
    ecs_os_free(json);

    return result;
}

void bmx_ecs_modified_component(ecs_world_t *world, BBULONG entityId, BBULONG componentId) {
ecs_entity_t e = (ecs_entity_t)entityId;

    if (!ecs_is_alive(world, e)) {
        return;
    }

    ecs_modified_id(world, e, (ecs_id_t)componentId);
}

BBULONG bmx_ecs_lookup(ecs_world_t *world, BBString *name) {
    char *n = (char*)bbStringToUTF8String(name);
    ecs_entity_t e = ecs_lookup(world, n);
    bbMemFree(n);
    return (BBULONG)e;
}

BBString *bmx_ecs_get_name(ecs_world_t *world, BBULONG entityId) {
    const char *name = ecs_get_name(world, (ecs_entity_t)entityId);

    if (!name) {
        return &bbEmptyString;
    }

    return bbStringFromUTF8String(name);
}

BBString *bmx_ecs_get_path(ecs_world_t *world, BBULONG entityId) {
    char *path = ecs_get_path(world, (ecs_entity_t)entityId);

    if (!path) {
        return &bbEmptyString;
    }

    BBString *result = bbStringFromUTF8String(path);
    ecs_os_free(path);

    return result;
}

BBULONG bmx_ecs_lookup_child(ecs_world_t *world, BBULONG parentId, BBString *name) {
    char *n = (char*)bbStringToUTF8String(name);
    ecs_entity_t e = ecs_lookup_child(world, (ecs_entity_t)parentId, n);
    bbMemFree(n);
    return (BBULONG)e;
}

BBString *bmx_ecs_get_path_from(ecs_world_t *world, BBULONG parentId, BBULONG childId) {
    char *path = ecs_get_path_w_sep(world, (ecs_entity_t)parentId, (ecs_entity_t)childId, "/", NULL);

    if (!path) {
        return &bbEmptyString;
    }

    BBString *result = bbStringFromUTF8String(path);
    ecs_os_free(path);

    return result;
}

void bmx_ecs_enable(ecs_world_t *world, BBULONG entityId, int enable) {
    ecs_enable(world, (ecs_entity_t)entityId, enable);
}

int bmx_ecs_is_enabled(ecs_world_t *world, BBULONG entity) {
    return ecs_has_id(world, (ecs_entity_t)entity, EcsDisabled) == 0;
}

void bmx_ecs_enable_component(ecs_world_t *world, BBULONG entity, BBULONG component, int enabled) {
    ecs_enable_id(world, (ecs_entity_t)entity, (ecs_id_t)component, enabled);
}

int bmx_ecs_is_component_enabled(ecs_world_t *world, BBULONG entity, BBULONG component) {
    return (int)ecs_is_enabled_id(world, (ecs_entity_t)entity, (ecs_id_t)component);
}

void bmx_ecs_set_can_toggle(ecs_world_t *world, BBULONG component) {
    ecs_add_id(world, (ecs_entity_t)component, EcsCanToggle);
}

void bmx_ecs_set_target_fps(ecs_world_t *world, float fps) {
    ecs_set_target_fps(world, fps);
}

void bmx_ecs_quit(ecs_world_t *world) {
    ecs_quit(world);
}

int bmx_ecs_should_quit(ecs_world_t *world) {
    return (int)ecs_should_quit(world);
}

void bmx_ecs_set_system_interval(ecs_world_t *world, BBULONG systemId, float interval) {
    ecs_set_interval(world, (ecs_entity_t)systemId, interval);
}

void bmx_ecs_set_system_rate(ecs_world_t *world, BBULONG systemId, int32_t rate) {
    ecs_set_rate(world, (ecs_entity_t)systemId, rate, 0);
}

void bmx_ecs_set_system_rate_source(ecs_world_t *world, BBULONG systemId, int32_t rate, BBULONG tickSource) {
    ecs_set_rate(world, (ecs_entity_t)systemId, rate, (ecs_entity_t)tickSource);
}

BBULONG bmx_ecs_new_timer(ecs_world_t *world, BBString *name, float interval) {
    char *n = (char*)bbStringToUTF8String(name);

    ecs_entity_t timer = ecs_entity_init(world, &(ecs_entity_desc_t){
        .name = n
    });

    ecs_set_interval(world, timer, interval);

    bbMemFree(n);

    return (BBULONG)timer;
}

BBULONG bmx_ecs_new_rate_filter(ecs_world_t *world, BBString *name, int32_t rate, BBULONG tickSource) {
    char *n = (char*)bbStringToUTF8String(name);

    ecs_entity_t filter = ecs_entity_init(world, &(ecs_entity_desc_t){
        .name = n
    });

    ecs_set_rate(world, filter, rate, (ecs_entity_t)tickSource);

    bbMemFree(n);

    return (BBULONG)filter;
}

void bmx_ecs_clear_entity(ecs_world_t *world, BBULONG entity) {
    ecs_clear(world, (ecs_entity_t)entity);
}

BBULONG bmx_ecs_clone_entity(ecs_world_t *world, BBULONG entity, int copyValue) {
    return (BBULONG)ecs_clone(world, 0, (ecs_entity_t)entity, copyValue);
}

void bmx_ecs_delete_with(ecs_world_t *world, BBULONG component) {
    ecs_delete_with(world, (ecs_id_t)component);
}

void bmx_ecs_remove_all(ecs_world_t *world, BBULONG component) {
    ecs_remove_all(world, (ecs_id_t)component);
}

void bmx_ecs_doc_set_brief(ecs_world_t *world, BBULONG entity, BBString *text) {
    char *s = (char*)bbStringToUTF8String(text);
    ecs_doc_set_brief(world, (ecs_entity_t)entity, s);
    bbMemFree(s);
}

BBString *bmx_ecs_doc_get_brief(ecs_world_t *world, BBULONG entity) {
    const char *s = ecs_doc_get_brief(world, (ecs_entity_t)entity);
    if (!s) return &bbEmptyString;
    return bbStringFromUTF8String(s);
}

void bmx_ecs_doc_set_detail(ecs_world_t *world, BBULONG entity, BBString *text) {
    char *s = (char*)bbStringToUTF8String(text);
    ecs_doc_set_detail(world, (ecs_entity_t)entity, s);
    bbMemFree(s);
}

BBString *bmx_ecs_doc_get_detail(ecs_world_t *world, BBULONG entity) {
    const char *s = ecs_doc_get_detail(world, (ecs_entity_t)entity);
    if (!s) return &bbEmptyString;
    return bbStringFromUTF8String(s);
}

void bmx_ecs_doc_set_color(ecs_world_t *world, BBULONG entity, BBString *color) {
    char *s = (char*)bbStringToUTF8String(color);
    ecs_doc_set_color(world, (ecs_entity_t)entity, s);
    bbMemFree(s);
}

BBString *bmx_ecs_doc_get_color(ecs_world_t *world, BBULONG entity) {
    const char *s = ecs_doc_get_color(world, (ecs_entity_t)entity);
    if (!s) return &bbEmptyString;
    return bbStringFromUTF8String(s);
}

void bmx_ecs_doc_set_link(ecs_world_t *world, BBULONG entity, BBString *link) {
    char *s = (char*)bbStringToUTF8String(link);
    ecs_doc_set_link(world, (ecs_entity_t)entity, s);
    bbMemFree(s);
}

BBString *bmx_ecs_doc_get_link(ecs_world_t *world, BBULONG entity) {
    const char *s = ecs_doc_get_link(world, (ecs_entity_t)entity);
    if (!s) return &bbEmptyString;
    return bbStringFromUTF8String(s);
}

void bmx_ecs_set_alias(ecs_world_t *world, BBULONG entity, BBString *alias) {
    char *s = (char*)bbStringToUTF8String(alias);
    ecs_set_alias(world, (ecs_entity_t)entity, s);
    bbMemFree(s);
}

void bmx_ecs_set_symbol(ecs_world_t *world, BBULONG entity, BBString *symbol) {
    char *s = (char*)bbStringToUTF8String(symbol);
    ecs_set_symbol(world, (ecs_entity_t)entity, s);
    bbMemFree(s);
}

BBString *bmx_ecs_get_symbol(ecs_world_t *world, BBULONG entity) {
    const char *s = ecs_get_symbol(world, (ecs_entity_t)entity);
    if (!s) return &bbEmptyString;
    return bbStringFromUTF8String(s);
}

BBULONG bmx_ecs_new_phase(ecs_world_t *world, BBString *name, BBULONG dependsOn) {
    char *n = (char*)bbStringToUTF8String(name);

    ecs_entity_t phase = ecs_entity_init(world, &(ecs_entity_desc_t){
        .name = n
    });

    ecs_add_id(world, phase, EcsPhase);

    if (dependsOn) {
        ecs_add_pair(world, phase, EcsDependsOn, (ecs_entity_t)dependsOn);
    }

    bbMemFree(n);

    return (BBULONG)phase;
}

void bmx_ecs_set_system_phase(ecs_world_t *world, BBULONG systemId, BBULONG phase) {
    ecs_entity_t system = (ecs_entity_t)systemId;

    ecs_remove_pair(world, system, EcsDependsOn, EcsWildcard);

    ecs_add_id(world, system, (ecs_id_t)phase);
    ecs_add_pair(world, system, EcsDependsOn, (ecs_entity_t)phase);
}

BBULONG bmx_ecs_new_pipeline(ecs_world_t *world, BBString *name, BBString *expr) {
    char *n = (char*)bbStringToUTF8String(name);
    char *e = (char*)bbStringToUTF8String(expr);

    ecs_entity_t entity = ecs_entity_init(world, &(ecs_entity_desc_t){
        .name = n
    });

    ecs_pipeline_desc_t desc = {0};
    desc.entity = entity;
    desc.query.expr = e;

    ecs_entity_t pipeline = ecs_pipeline_init(world, &desc);

    bbMemFree(e);
    bbMemFree(n);

    return (BBULONG)pipeline;
}

void bmx_ecs_set_pipeline(ecs_world_t *world, BBULONG pipeline) {
    ecs_set_pipeline(world, (ecs_entity_t)pipeline);
}

BBULONG bmx_ecs_get_pipeline(ecs_world_t *world) {
    return (BBULONG)ecs_get_pipeline(world);
}

void bmx_ecs_run_pipeline(ecs_world_t *world, BBULONG pipeline, float deltaTime) {
    ecs_run_pipeline(world, (ecs_entity_t)pipeline, deltaTime);
}

void bmx_ecs_enable_stats(ecs_world_t *world) {
    ECS_IMPORT(world, FlecsStats);
}

int bmx_ecs_get_stats(ecs_world_t *world, bmx_ecs_world_stats_t *stats) {
    const EcsWorldSummary *summary = ecs_get(world, world, EcsWorldSummary);

    if (!summary) {
        return 0;
    }

    stats->entityCount = summary->entity_count;
    stats->tableCount = summary->table_count;

    stats->componentCount = summary->component_count;
    stats->tagCount = summary->tag_count;
    stats->pairCount = summary->pair_count;

    return 1;
}

///////////////////////////////////////////////////////////

int bmx_ecs_iter_count(ecs_iter_t *iter) {
    return iter->count;
}

void bmx_ecs_field_w_size(ecs_iter_t *iter, size_t size, int index, void **data) {
    *data = ecs_field_w_size(iter, size, (int8_t)index);
}

BBULONG bmx_ecs_iter_entity(ecs_iter_t *iter, int index) {
    return (BBULONG)iter->entities[index];
}

int bmx_ecs_iter_field_is_self(ecs_iter_t *it, int32_t index) {
    return (int)ecs_field_is_self(it, (int8_t)index);
}

float bmx_ecs_iter_delta_time(ecs_iter_t *it) {
    return it->delta_time;
}

BBULONG bmx_ecs_iter_field_id(ecs_iter_t *it, int32_t index) {
    return (BBULONG)ecs_field_id(it, (int8_t)index);
}

BBULONG bmx_ecs_iter_pair_first(ecs_iter_t *it, int32_t index) {
    return (BBULONG)ecs_pair_first(it, (int8_t)index);
}

BBULONG bmx_ecs_iter_pair_second(ecs_iter_t *it, int32_t index) {
    return (BBULONG)ecs_pair_second(it, (int8_t)index);
}

int bmx_ecs_iter_is_true(ecs_iter_t *it) {
    return (int)ecs_iter_is_true(it);
}

int bmx_ecs_iter_changed(ecs_iter_t *it) {
    return (int)ecs_iter_changed(it);
}

void bmx_ecs_iter_skip(ecs_iter_t *it) {
    ecs_iter_skip(it);
}

////////////////////////////////////////////////////////////

void bmx_ecs_query_reset(bmx_ecs_query_t *query) {
    query->iter = ecs_query_iter(query->query->world, query->query);
}

int bmx_ecs_query_advance(bmx_ecs_query_t *query) {
    return ecs_query_next(&query->iter);
}

ecs_iter_t *bmx_ecs_query_current(bmx_ecs_query_t *query) {
    return &query->iter;
}

void bmx_ecs_query_each(ecs_world_t *world, bmx_ecs_query_t *query) {
    ecs_iter_t it = ecs_query_iter(world, query->query);
    while (ecs_query_next(&it)) {
        bmx_ecs_query_callback(&it);
    }
}

void bmx_ecs_query_destroy(ecs_world_t *world, bmx_ecs_query_t *query) {
    ecs_query_fini(query->query);
    free(query);
}

void bmx_ecs_query_reset_group(bmx_ecs_query_t *query, uint64_t group_id) {
    query->iter = ecs_query_iter(query->query->world, query->query);
    ecs_iter_set_group(&query->iter, group_id);
}
