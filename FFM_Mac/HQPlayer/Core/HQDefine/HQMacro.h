//
//  HQMacro.h
//  FFM_Mac
//
//  Created by 黄麒展 on 2020/3/5.
//  Copyright © 2020 黄麒展. All rights reserved.
//

#ifndef HQMacro_h
#define HQMacro_h

/// block 强弱引用
#define HQWeakify(obj) __weak typeof(obj) weak_obj = obj;
#define HQStrongify(obj) __strong typeof(weak_obj) obj = weak_obj;

/// log
#ifdef DEBUG
#define HQPlayerLog(...) NSLog(__VA_ARGS__)
#else
#define HQPlayerLog(...)
#endif


///  get 方法
#define HQGetoMap(type, name0, obj) - (type)name0{ return obj.name0; }
#define HQGet1Map(type, name0, type0, obj) - (type)name0:(type0)n0 {return [obj name0:n0];}
#define HQGet00Map(type, name0, name00, obj) - (type)name0 {return obj.name00;}
#define HQGet11Map(type, name0, name00, type0, obj) - (type)name0:(type0)n0 {return [obj name00:n0];}

/// set方法
#define HQSet1Map(type, name0, type0, obj) - (type)name0:(type0)n0 {[obj name0:n0];}
#define HQSet2Map(type, name0, type0, name1, type1, obj) - (type)name0:(type0)n0 name1:(type1)n1 {[obj name0:n0 name1:n1];}
#define HQSet11Map(type, name0, name00, t0, obj) - (type)name0:(t0)n0 {[obj name00:n0];}
#define HQSet22Map(type, name0, name00, type0, name1, name11, type1, obj) - (type)name0:(type0)n0 name1:(type1)n1 {[obj name00:n0 name11:n1];}



#endif /* HQMacro_h */
