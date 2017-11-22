// Copyright (c) Microsoft. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.

// This file gets included into refcount.h as a means of extending the behavior of
// atomic increment, decrement, and test. It gets included in two separate phases
// in order to make the macro definitions work properly.
#ifndef REFCOUNT_OS_H__ARDUINO
#define REFCOUNT_OS_H__ARDUINO

// Arduino user code is inherently single-threaded, so we don't 
// need atomic operations 
#define COUNT_TYPE uint32_t

#endif // REFCOUNT_OS_H__ARDUINO

// This is the second phase inclusion
#ifdef REFCOUNT_OS_H__PHASE_TWO
#undef REFCOUNT_OS_H__PHASE_TWO
#ifndef REFCOUNT_OS_H__PHASE_TWO__IMPL
#define REFCOUNT_OS_H__PHASE_TWO__IMPL


/*if macro DEC_REF returns DEC_RETURN_ZERO that means the ref count has reached zero.*/
#define DEC_RETURN_ZERO (0)
#define INC_REF(type, var) ++((((REFCOUNT_TYPE(type)*)var)->count))
#define DEC_REF(type, var) --((((REFCOUNT_TYPE(type)*)var)->count))

#endif // REFCOUNT_OS_H__PHASE_TWO__IMPL
#endif // REFCOUNT_OS_H__PHASE_TWO
