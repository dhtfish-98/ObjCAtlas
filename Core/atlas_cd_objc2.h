struct atlas_cd_objc2_list_header {
    uint32_t atlas_entsize;
    uint32_t atlas_count;
};

struct atlas_cd_objc2_image_info {
    uint32_t atlas_version;
    uint32_t atlas_flags;
};


//
// 64-bit, also holding 32-bit
//

struct atlas_cd_objc2_class {
    uint64_t atlas_isa;
    uint64_t atlas_superclass;
    uint64_t atlas_cache;
    uint64_t atlas_vtable;
    uint64_t atlas_data; // points to class_ro_t
    uint64_t atlas_reserved1;
    uint64_t atlas_reserved2;
    uint64_t atlas_reserved3;
};

struct atlas_cd_objc2_class_ro_t {
    uint32_t atlas_flags;
    uint32_t atlas_instanceStart;
    uint32_t atlas_instanceSize;
    uint32_t atlas_reserved; // *** this field does not exist in the 32-bit version ***
    uint64_t atlas_ivarLayout;
    uint64_t atlas_name;
    uint64_t atlas_baseMethods;
    uint64_t atlas_baseProtocols;
    uint64_t atlas_ivars;
    uint64_t atlas_weakIvarLayout;
    uint64_t atlas_baseProperties;
};

struct atlas_cd_objc2_method {
    uint64_t atlas_name;
    uint64_t atlas_types;
    uint64_t atlas_imp;
};

struct atlas_cd_objc2_ivar {
    uint64_t atlas_offset;
    uint64_t atlas_name;
    uint64_t atlas_type;
    uint32_t atlas_alignment;
    uint32_t atlas_size;
};

struct atlas_cd_objc2_property {
    uint64_t atlas_name;
    uint64_t atlas_attributes;
};

struct atlas_cd_objc2_protocol {
    uint64_t atlas_isa;
    uint64_t atlas_name;
    uint64_t atlas_protocols;
    uint64_t atlas_instanceMethods;
    uint64_t atlas_classMethods;
    uint64_t atlas_optionalInstanceMethods;
    uint64_t atlas_optionalClassMethods;
    uint64_t atlas_instanceProperties; // So far, always 0
    uint32_t atlas_size; // sizeof(cd_objc2_protocol)
    uint32_t atlas_flags;
    uint64_t atlas_extendedMethodTypes;
};

struct atlas_cd_objc2_category {
    uint64_t atlas_name;
    uint64_t atlas_class;
    uint64_t atlas_instanceMethods;
    uint64_t atlas_classMethods;
    uint64_t atlas_protocols;
    uint64_t atlas_instanceProperties;
    uint64_t atlas_v7;
    uint64_t atlas_v8;
};
