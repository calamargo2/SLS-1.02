                    /* xctolu.h */


/* this table converts an MS-DOS screen code to a LINUX screen code */

    unsigned char codelu[] = {

        0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
        0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
        0x10, 0x11, 0x12, 0x13, 0xb6, 0xa7, 0x16, 0x17,
        0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
        0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27,
        0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f,
        0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37,
        0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f,
        0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47,
        0x48, 0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f,
        0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57,
        0x58, 0x59, 0x5a, 0x5b, 0x5c, 0x5d, 0x5e, 0x5f,
        0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67,
        0x68, 0x69, 0x6a, 0x6b, 0x6c, 0x6d, 0x6e, 0x6f,
        0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77,
        0x78, 0x79, 0x7a, 0x7b, 0x7c, 0x7d, 0x7e, 0x7f, 

        0xc7, 0xfc, 0xe9, 0xe2, 0xe4, 0xe0, 0xe5, 0xe7,   /* 87 */
        0xea, 0xeb, 0xe8, 0xef, 0xee, 0xec, 0xc4, 0xc5,   /* 8f */
        0xc9, 0xe6, 0xc6, 0xf4, 0xf6, 0xf2, 0xfb, 0xf9,   /* 97 */ 
        0xff, 0xd6, 0xdc, 0xa2, 0xa3, 0xa5, 0x50, 0x66,   /* 9f */ 
        0xe1, 0xed, 0xf3, 0xfa, 0xf1, 0xd1, 0xaa, 0xba,   /* a7 */
        0xbf, 0xad, 0xac, 0xbd, 0xbc, 0xa1, 0xab, 0xbb,   /* af */ 
        0xfe, 0xfe, 0xfe, 0xa6, 0xa6, 0xa6, 0xa6, 0xfe,   /* b7 */
        0xfe, 0xa6, 0xa6, 0xfe, 0xfe, 0xfe, 0xfe, 0xfe,   /* bf */
        0xfe, 0xad, 0xad, 0xa6, 0xad, 0x2b, 0xa6, 0xa6,   /* c7 */
        0xfe, 0xfe, 0xad, 0xad, 0xa6, 0xad, 0x2b, 0xad,   /* cf */
        0xad, 0xad, 0xad, 0xfe, 0xfe, 0xfe, 0xfe, 0x2b,   /* d7 */
        0x2b, 0xfe, 0xfe, 0xfe, 0xfe, 0xfe, 0xfe, 0xfe,   /* df */
        0xa3, 0xdf, 0xfe, 0xfe, 0x53, 0x73, 0xb5, 0x74,   /* e7 */
        0xa7, 0x4f, 0x4f, 0x64, 0xad, 0x6f, 0xc6, 0xfe,   /* ef */ 
        0xad, 0xb1, 0xfe, 0xfe, 0xa6, 0xa6, 0xf7, 0x7e,   /* f7 */
        0xb0, 0xb7, 0xb7, 0x76, 0x6e, 0xb2, 0xfe, 0x20 } ;


/* this table converts a LINUX screen code to an MS-DOS screen code */

    unsigned char codepc[] = {

        0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
        0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
        0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
        0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
        0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27,
        0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f,
        0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37,
        0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f,
        0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47,
        0x48, 0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f,
        0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57,
        0x58, 0x59, 0x5a, 0x5b, 0x5c, 0x5d, 0x5e, 0x5f,
        0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67,
        0x68, 0x69, 0x6a, 0x6b, 0x6c, 0x6d, 0x6e, 0x6f,
        0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77,
        0x78, 0x79, 0x7a, 0x7b, 0x7c, 0x7d, 0x7e, 0x7f, 

        0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87,  /* 87 */
        0x88, 0x89, 0x8a, 0x8b, 0x8c, 0x8d, 0x8e, 0x8f,  /* 8f */
        0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97,  /* 97 */
        0x98, 0x99, 0x9a, 0x9b, 0x9c, 0x9d, 0x9e, 0x9f,  /* 9f */
        0x20, 0xad, 0x9b, 0x9c, 0xfe, 0x9d, 0x7c, 0xfe,  /* a7 */
        0xfe, 0xfe, 0xa6, 0xae, 0xaa, 0x2d, 0xfe, 0xfe,  /* af */
        0xf8, 0xf1, 0xfd, 0xfe, 0xfe, 0xe6, 0xfe, 0xf9,  /* b7 */
        0xfe, 0xfe, 0x97, 0xaf, 0xac, 0xab, 0xfe, 0xa8,  /* bf */
        0xfe, 0xfe, 0xfe, 0xfe, 0x8e, 0x8f, 0x92, 0x80,  /* c7 */
        0xfe, 0x90, 0xfe, 0xfe, 0xfe, 0xfe, 0xfe, 0xfe,  /* cf */
        0xfe, 0xa5, 0xfe, 0xfe, 0xfe, 0xfe, 0x99, 0xfe,  /* d7 */
        0xfe, 0xfe, 0xfe, 0xfe, 0x9a, 0xfe, 0xfe, 0xe1,  /* df */
        0x85, 0xa0, 0x83, 0xfe, 0x84, 0x86, 0x91, 0x87,  /* e7 */
        0x8a, 0x82, 0x88, 0x89, 0x8d, 0xa1, 0x8c, 0x8b,  /* ef */
        0xfe, 0xa4, 0x95, 0xa2, 0x93, 0xfe, 0x94, 0xf6,  /* f7 */
        0xfe, 0x97, 0xa3, 0x96, 0x81, 0xfe, 0xfe, 0x98 } ;
