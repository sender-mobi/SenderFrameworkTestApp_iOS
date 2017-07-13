//
//  RSAManager.m
//  SENDER
//
//  Created by Eugene Gilko on 11/26/15.
//  Copyright © 2015 Middleware Inc. All rights reserved.
//

#import "RSAManager.h"
#import "SecGenerator.h"
#import "CoreDataFacade.h"
#import <Security/Security.h>
#import <CommonCrypto/CommonCryptoError.h>
#import "NSData+CommonCrypto.h"

#include <openssl/err.h>
#include <openssl/rand.h>
#include <openssl/md5.h>
#include <openssl/sha.h>
#include <openssl/evp.h>
#include <openssl/rsa.h>
#include <openssl/hmac.h>
#include <openssl/pem.h>
#include <openssl/x509.h>

#import "ServerFacade.h"
#import "RSAHelper.h"
#import "base64.h"

#import "SENDER-Swift.h"
//const size_t BUFFER_SIZE = 128;
//const size_t CIPHER_BUFFER_SIZE = 1024;
//const uint32_t PADDING = kSecPaddingNone;

@interface RSAManager()
{
    RSA * MY_RSA;
}

@end

@implementation RSAManager

- (id)init
{
    self = [super init];
    if (self) {
        
        publicTagString = @"sender.main.publickey1";
        privateTagString = @"sender.main.privatekey1";
        privateTag = [self convertTAGStringToData:privateTagString];
        publicTag = [self convertTAGStringToData:publicTagString];
    }
    
    return self;
}


- (void)generateRSAKeys
{
    NSString * ketAes = [self generateTempKey];
    
    NSData *toencrypt = [@"Message" dataUsingEncoding:NSASCIIStringEncoding];
    
    NSData *pass = [ketAes dataUsingEncoding:NSASCIIStringEncoding];
    
    NSData *iv = [@"1010101010101010" dataUsingEncoding:NSASCIIStringEncoding];
    
    CCCryptorStatus status = kCCSuccess;
    
    NSData * encrypted = [toencrypt dataEncryptedUsingAlgorithm:kCCAlgorithmAES128 key:pass initializationVector:iv options:kCCOptionPKCS7Padding error:&status];
    
    NSString *text = base64_encode_data(encrypted);
    
    NSData * sourceData = [[SecGenerator sharedInstance] encodeKeyForExport:@"Message" withKey:@"101112131415161718191a1b1c1d1e1f"];
                           
    
  
    const unsigned char * buffer = (const unsigned char *)[sourceData bytes];
    NSString * keyString = [NSMutableString stringWithCapacity:sourceData.length * 2];
    
    for (int i = 0; i < sourceData.length; ++i)
        keyString = [keyString stringByAppendingFormat:@"%02lx", (unsigned long)buffer[i]];
    
    
    int KEY_SIZE = 512;
    
    CryptoExportImportManager * cryptoManager = [[CryptoExportImportManager alloc] init];
    
    [cryptoManager deleteSecureKeyPair:publicTagString completion:^(BOOL code) {
        
        [cryptoManager createSecureKeyPair:publicTagString keySize:KEY_SIZE completion:^(BOOL code, NSData * result) {
            NSData * keyData = [cryptoManager getPublicKeyData:publicTagString];
            
            NSData * derData = [cryptoManager exportECPublicKeyToDER:keyData keyType:@"RSA" keySize:KEY_SIZE];
            
            NSString * derString = base64_encode_data(derData);
            
            NSString * pemString = [cryptoManager exportPublicKeyToPEM:keyData keyType:@"RSA" keySize:KEY_SIZE];
            
            
            pemString = @"-----BEGIN PUBLIC KEY-----MFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBANtwFlTOnYPBpAgKUkGrdCdKky12Xm168vT48puaPHFQia4oZo9SkgZbXFMPIZXS52NtqS5UA2vhOnyf6iMqSScCAwEAAQ==-----END PUBLIC KEY-----";
            
            
            //        NSString * pemString = @"-----BEGIN PUBLIC KEY-----MF0wDQYJKoZIhvcNAQEBBQADSwAwSAJBAMTM7uw3m+znOJIELyZVAnSFXnDD4LTi0qslQju6rTkjXXUKjMDgUC0Ur2WCSHSlHNlU649HD2TAqGb40UA/ql8CAwEAAQ==-----END PUBLIC KEY-----";
            //
            

            NSString * try = [RSAHelper encryptString:@"This is test string!" publicKey:pemString];
            
            NSLog(@"TRY IS %@", try);
        }];
    }];

        
//    [self generateKeyPair:1024];
    
    
   
//    RSAPubDecoder * rsaDec = [[RSAPubDecoder alloc] init];
//    NSData * puKData1 = [rsaDec getPublicKeyDataForTAG:publicTag];
//    NSData * puKData = [self getPublicKeyBitsFromKey:publicKey];
    
    return;
    
//    int blockSize = SecKeyGetBlockSize( publicKey ) ;
//    printf( "THE MAX LENGTH OF DATA I CAN ENCRYPT IS %d BYTES\n", blockSize ) ;
//    
//    uint8_t *binaryData = (uint8_t *)malloc( blockSize ) ;
//    for( int i = 0 ; i < blockSize ; i++ )
//        binaryData[i] = 'A' + (i % 26 ) ; // loop the alphabet
//    binaryData[ blockSize-1 ] = 0 ; // NULL TERMINATED ;)
//    printf( "ORIGINAL DATA:\n%s\n", (char*)binaryData ) ;
//    
//    uint8_t *encrypted = (uint8_t *)malloc( blockSize ) ;
//    size_t encryptedLen = blockSize ; // MUST set this to the size of encrypted, otherwise SecKeyEncrypt may fail.
//    // Docs: "cipherTextLen: On entry, the size of the buffer provided in the cipherText parameter. On return, the amount of data actually placed in the buffer."
//    SecKeyEncrypt( publicKey, kSecPaddingPKCS1, binaryData, blockSize, encrypted, &encryptedLen );
//
//    NSString * dd =  [[NSString alloc] initWithBytes:encrypted length:sizeof(encrypted) encoding:NSUTF8StringEncoding];
//
//    NSLog(@"RETURNED FROM HELL %@", dd);
//    free( binaryData ) ;
//    
//    printf( "ENCODED %d bytes => %lu bytes\n", blockSize, encryptedLen );
//    
//    int base64DataLen ;
//    char* base64Data = base64( encrypted, encryptedLen, &base64DataLen ) ;
//    printf( "B64( ENCRYPTED( <<BINARY DATA>> ) ) as %d base64 ascii chrs:\n%s\n", base64DataLen, base64Data ) ;
//    
    
    
    
    
    
    
    
//    NSString * pubkey = [self base64StingFromData:puKData];
    
    NSString * rr = @"-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAtFbH+5JTbsK38gRt5S5K\nVX9VQHUro1TyCsxUCqD7KVlGP4EWFSLriAznu+FvnN3o5hcu1gWYt4O2sZGlRVZD\na1HYSrfYx4xUp3Rso1/js7wjlg21o7iVKHGn3N+cZk17lUOUpzA0ViVdnH7X4yax\nNTrwZKvWKi5Vo73j1Id7rfQ8kd/Q8D2f8JaMBty6Rme3r2QC3rD8mggJKI1YBHy1\nJ282k6Y8ol/AD9lMeXg/FClkkaqYUbS9b9427b7zJRKQ13yRYpJhdHIu4x1j/3tf\n8LNv3Cjb8XfSxOXwXVro6Xq1DRJtoE6iwv8jBFJmO3ipIbI8moSypNVbUMR2kw8m\nMQIDAQAB\n-----END PUBLIC KEY-----";
    
    
    NSString * encWithPubKey = [RSAHelper encryptString:@"Just Test String" publicKey:rr];
    
//    publicKey
//    privateKeyRSA
    

//    NSString * base64_PUB_KEY = [derData base64EncodedStringWithOptions:0];
    
//    [[ServerFacade sharedInstance]setSelfInfo:@{@"msgKey" : base64_PUB_KEY} withRequestHandler:^(NSDictionary *response, NSError *error) {
//
//    }];

//    [CoreDataFacade sharedInstance].getOwner.privateKey = privateRSAKey;
//    [CoreDataFacade sharedInstance].getOwner.publicKey = base64_PUB_KEY;
//    [[CoreDataFacade sharedInstance] saveContext];
}



- (void)testDD {
    
    EVP_PKEY_CTX *ctx;
    EVP_PKEY *pkey = NULL;
    ctx = EVP_PKEY_CTX_new_id(EVP_PKEY_RSA, NULL);
    if (!ctx) {
    /* Error occurred */
    }
        if (EVP_PKEY_keygen_init(ctx) <= 0){
        /* Error */
        }
            if (EVP_PKEY_CTX_set_rsa_keygen_bits(ctx, 2048) <= 0){
            /* Error */
            }
    
            /* Generate key */
                if (EVP_PKEY_keygen(ctx, &pkey) <= 0){
                                            
                /* Error */
                }
    
    int KEY_LENGTH = 512;
    
    RSA *keypair = RSA_generate_key(KEY_LENGTH, 3, NULL, NULL);
    
    BIO *pri = BIO_new(BIO_s_mem());
    BIO *pub = BIO_new(BIO_s_mem());
    
    PEM_write_bio_RSAPrivateKey(pri, keypair, NULL, NULL, 0, NULL, NULL);
    PEM_write_bio_RSAPublicKey(pub, keypair);
    
    size_t pri_len = BIO_pending(pri);
    size_t pub_len = BIO_pending(pub);
    
    char *pri_key = malloc(pri_len + 1);
    char *pub_key = malloc(pub_len + 1);
    
    BIO_read(pri, pri_key, pri_len);
    BIO_read(pub, pub_key, pub_len);
    
    pri_key[pri_len] = '\0';
    pub_key[pub_len] = '\0';
    
    printf("\n%s\n%s\n", pri_key, pub_key);
    
    
    unsigned char * base64DecodeOutput;
    size_t test;
    Base64Decode(strdup(pub_key), &base64DecodeOutput, &test);
    
    NSUInteger base64Length = (int)calcDecodeLength((const char *)base64DecodeOutput);
    NSData * base64data = [NSData dataWithBytesNoCopy:base64DecodeOutput length:base64Length freeWhenDone:NO];
    NSString * base64String = [[NSString alloc] initWithData:base64data encoding:NSUTF8StringEncoding];
    
    NSLog(@"RETURNED FROM HELL %@", base64String);

    printf("Message to encrypt: ");
    char msg[] = "Hello world!";
    msg[strlen(msg)] = '\0';    // Get rid of the newline
    
    // Encrypt the message
    char *encrypt = malloc(RSA_size(keypair));
    int encrypt_len;
    char *err = malloc(130);
    if((encrypt_len = RSA_public_encrypt(strlen(msg)+1, (unsigned char*)msg,
                                         (unsigned char*)encrypt, keypair, RSA_PKCS1_OAEP_PADDING)) == -1) {
      
        fprintf(stderr, "Error encrypting message: %s\n", err);
    }
    
    
    char *decrypt = malloc(RSA_size(keypair));
    if(RSA_private_decrypt(encrypt_len, (unsigned char*)encrypt, (unsigned char*)decrypt,
                           keypair, RSA_PKCS1_OAEP_PADDING) == -1) {
 
        fprintf(stderr, "Error decrypting message: %s\n", err);
    } else {
        printf("Decrypted message: %s\n", decrypt);
    }
    
}


- (void)generateKeyPair:(NSUInteger)keySize
{
    OSStatus sanityCheck = noErr;
    publicKey = NULL;
    privateKeyRSA = NULL;
    
    NSMutableDictionary * privateKeyAttr = [[NSMutableDictionary alloc] init];
    NSMutableDictionary * publicKeyAttr = [[NSMutableDictionary alloc] init];
    NSMutableDictionary * keyPairAttr = [[NSMutableDictionary alloc] init];
    
    // Set top level dictionary for the keypair.
    
    [keyPairAttr setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [keyPairAttr setObject:[NSNumber numberWithUnsignedInteger:keySize] forKey:(__bridge id)kSecAttrKeySizeInBits];
    
    // Set the private key dictionary.
    [privateKeyAttr setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecAttrIsPermanent];
    [privateKeyAttr setObject:privateTagString forKey:(__bridge id)kSecAttrApplicationTag];
    // See SecKey.h to set other flag values.
    
    // Set the public key dictionary.
    [publicKeyAttr setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecAttrIsPermanent];
    [publicKeyAttr setObject:publicTagString forKey:(__bridge id)kSecAttrApplicationTag];
    // See SecKey.h to set other flag values.
    
    // Set attributes to top level dictionary.
    [keyPairAttr setObject:privateKeyAttr forKey:(__bridge id)kSecPrivateKeyAttrs];
    [keyPairAttr setObject:publicKeyAttr forKey:(__bridge id)kSecPublicKeyAttrs];
    
    // SecKeyGeneratePair returns the SecKeyRefs just for educational purposes.
    sanityCheck = SecKeyGeneratePair((__bridge CFDictionaryRef)keyPairAttr, &publicKey, &privateKeyRSA);
    //  LOGGING_FACILITY( sanityCheck == noErr && publicKey != NULL && privateKey != NULL, @"Something really bad went wrong with generating the key pair." );
    if(sanityCheck == noErr  && publicKey != NULL && privateKeyRSA != NULL)
    {
        NSLog(@"Successful");
    }
}

- (NSData *)getPublicKeyBitsFromKey:(SecKeyRef)givenKey
{
    static const uint8_t publicKeyIdentifier[] = "com.Sender.temp.publickey";
    NSData * publicTagTmp = [[NSData alloc] initWithBytes:publicKeyIdentifier length:sizeof(publicKeyIdentifier)];
    
    OSStatus sanityCheck = noErr;
    NSData * publicKeyBits = nil;
    
    NSMutableDictionary * queryPublicKey = [[NSMutableDictionary alloc] init];
    [queryPublicKey setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [queryPublicKey setObject:publicTagTmp forKey:(__bridge id)kSecAttrApplicationTag];
    [queryPublicKey setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [queryPublicKey setObject:(__bridge id)kSecAttrKeyClassPublic forKey:(__bridge id)kSecAttrKeyClass];

    NSMutableDictionary * attributes = [queryPublicKey mutableCopy];
    [attributes setObject:(__bridge id)givenKey forKey:(__bridge id)kSecValueRef];
    [attributes setObject:@YES forKey:(__bridge id)kSecReturnData];
    CFTypeRef result;
    sanityCheck = SecItemAdd((__bridge CFDictionaryRef) attributes, &result);
    if (sanityCheck == errSecSuccess) {
        publicKeyBits = CFBridgingRelease(result);
        
        (void)SecItemDelete((__bridge CFDictionaryRef) queryPublicKey);
    }
    
    return publicKeyBits;
}

- (NSData *)convertTAGStringToData:(NSString *)sourceString
{
    NSMutableArray * prArray = [NSMutableArray array];
    for (int i = 0; i < [sourceString length]; i++) {
        NSString * ch = [sourceString substringWithRange:NSMakeRange(i, 1)];
        [prArray addObject:ch];
    }
    return [[NSData alloc] initWithBytes:(__bridge const void * _Nullable)(prArray) length:(NSUInteger)prArray.count];
}

#pragma mark Start

- (NSString *)encodeMessage:(NSString *)messageText
          andSaveToMessage:(Message *)message
         withUserPublicKey:(NSString *)pubKey
{
    NSString * chiperKey = [self generateTempKey];
    
    return chiperKey;
}

#pragma mark EncryptWithCustomPUBKey

- (NSData *)random128BitAESKey {
    unsigned char buf[16];
    arc4random_buf(buf, sizeof(buf));
    return [NSData dataWithBytes:buf length:sizeof(buf)];
}

- (NSString *)generateTempKey
{
    NSData * keyData = [self random128BitAESKey];
    
    const unsigned char *dataBuffer = (const unsigned char *)[keyData bytes];
    
    if (!dataBuffer)
        return [NSString string];
    
    NSUInteger          dataLength  = [keyData length];
    NSMutableString     *hexString  = [NSMutableString stringWithCapacity:(dataLength * 2)];
    
    for (int i = 0; i < dataLength; ++i)
        [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];
    
    return [NSString stringWithString:hexString];
}

- (NSString *)encrypt_ChiperKey:(NSString *)chKey publicKey:(NSString *)pubkey
{
    NSString * encWithPubKey = [RSAHelper encryptString:chKey publicKey:pubkey];
    return encWithPubKey;
}

//
//- (void)testOpenSSL
//{
//    MY_RSA = RSA_generate_key(2048, RSA_F4, NULL, NULL);
//
//    BIO * pri = BIO_new(BIO_s_mem());
//    BIO * pub = BIO_new(BIO_s_mem());
//
//    PEM_write_bio_RSAPrivateKey(pri, MY_RSA, NULL, NULL, 0, NULL, NULL);
//    PEM_write_bio_RSAPublicKey(pub, MY_RSA);
//
//    size_t pri_len = BIO_pending(pri);
//    size_t pub_len = BIO_pending(pub);
//
//    char * pri_key = malloc(pri_len + 1);
//    char * pub_key = malloc(pub_len + 1);
//
//    BIO_read(pri, pri_key, (int) pri_len);
//    BIO_read(pub, pub_key, (int) pub_len);
//
//    pri_key[pri_len] = '\0';
//    pub_key[pub_len] = '\0';
//
//    NSString * outPrivateString = [NSString stringWithFormat:@"%s", pri_key];
//    NSLog(@"%@", outPrivateString);
//
//    NSString * outPublicString = [NSString stringWithFormat:@"%s", pub_key];
//    NSLog(@"%@", outPublicString);
//
//    NSRange spos = [outPublicString rangeOfString:@"-----BEGIN RSA PUBLIC KEY-----"];
//    NSRange epos = [outPublicString rangeOfString:@"-----END RSA PUBLIC KEY-----"];
//    if(spos.location != NSNotFound && epos.location != NSNotFound){
//        NSUInteger s = spos.location + spos.length;
//        NSUInteger e = epos.location;
//        NSRange range = NSMakeRange(s, e-s);
//        outPublicString = [outPublicString substringWithRange:range];
//    }
//
//    outPublicString = [NSString stringWithFormat:@"-----BEGIN PUBLIC KEY-----%@-----END PUBLIC KEY-----",outPublicString];
//
//    NSString *privkey = outPrivateString;
//
//    NSString *pubkey = outPublicString;
//
//    NSString *originString = @"hello world!";
//    for(int i=0; i<2; i++){
//        originString = [originString stringByAppendingFormat:@" %@", originString];
//    }
//    NSString *encWithPubKey;
//    NSString *decWithPrivKey;
//
//    NSLog(@"Original string(%d): %@", (int)originString.length, originString);
//
//    // Demo: encrypt with public key
//    encWithPubKey = [RSAHelper encryptString:originString publicKey:pubkey];
//    NSLog(@"Enctypted with public key: %@", encWithPubKey);
//    // Demo: decrypt with private key
//    decWithPrivKey = [RSAHelper decryptString:encWithPubKey privateKey:privkey];
//    NSLog(@"Decrypted with private key: %@", decWithPrivKey);
//}


//    char *myCharArray = (char *)[outPublicString UTF8String];
//    
//    
//    
//    char * p33uy = malloc(1);
//    
//    int yyy = strlen(myCharArray);
//    
//    int i;
//    for (i = 0 ; i < yyy; i++) {
//        p33uy[i] = myCharArray[i];
//    }
//    
//    p33uy[strlen(p33uy)] = '\0';
//   
    
//     RSA *rsa_publickey1 = createRSA((unsigned char *)myCharArray, 1);

    
    
//    
//    NSMutableArray * stringArray = [NSMutableArray array];
//    for (int i = 0; i < [outPublicString length]; i++) {
//        NSString * ch = [outPublicString substringWithRange:NSMakeRange(i, 1)];
//        [stringArray addObject:ch];
//    }
//
//    const unsigned char * enc_data = (unsigned char *) malloc(stringArray.count);
//    enc_data = (__bridge const void * _Nullable)(stringArray);

    
    
//    p33uy = [outPublicString UTF8String];
    
//    char puy[] = "-----BEGIN PUBLIC KEY-----\n"
//    "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAy8Dbv8prpJ/0kKhlGeJY\n"
//    "ozo2t60EG8L0561g13R29LvMR5hyvGZlGJpmn65+A4xHXInJYiPuKzrKUnApeLZ+\n"
//    "vw1HocOAZtWK0z3r26uA8kQYOKX9Qt/DbCdvsF9wF8gRK0ptx9M6R13NvBxvVQAp\n"
//    "fc9jB9nTzphOgM4JiEYvlV8FLhg9yZovMYd6Wwf3aoXK891VQxTr/kQYoq1Yp+68\n"
//    "i6T4nNq7NWC+UNVjQHxNQMQMzU6lWCX8zyg3yH88OAQkUXIXKfQ+NkvYQ1cxaMoV\n"
//    "PpY72+eVthKzpMeyHkBn7ciumk5qgLTEJAfWZpe4f4eFZj/Rc8Y8Jj2IS5kVPjUy\n"
//    "wQIDAQAB\n"
//    "-----END PUBLIC KEY-----\n";
//
//    NSLog(@"%c",puy);
//    
////    RSA *rsa_publickey = createRSA((unsigned char *)puy, 1);
////    int rr = strlen(puy);
//    
//    NSString * decStaring = [self encryptString:@"Mega Test String" publicKey:outPublicString];
//    
//    uint8_t * myIntArray = (uint8_t *)[decStaring UTF8String];
//    
//    SecKeyRef privK = [self getPrivateKey:outPrivateString];
//    
//    const size_t CIPHER_BUFFER_SIZE = 1024;
//    uint8_t *cipherBuffer;
//    uint8_t *decryptedBuffer;
//    const size_t BUFFER_SIZE = 64;
//    
//    cipherBuffer = (uint8_t *)calloc(CIPHER_BUFFER_SIZE, sizeof(uint8_t));
//    decryptedBuffer = (uint8_t *)calloc(BUFFER_SIZE, sizeof(uint8_t));
//    
//    cipherBuffer = myIntArray;
//    
//    [self decryptWithPrivateKey:cipherBuffer plainBuffer:decryptedBuffer prKey:privK];
//    NSLog(@"decrypted data: %s", decryptedBuffer);
//}

- (void)decryptWithPrivateKey:(uint8_t *)cipherBuffer plainBuffer:(uint8_t *)plainBuffer prKey:(SecKeyRef)privK
{
    const size_t BUFFER_SIZE = 265;
    
    OSStatus status = noErr;
    
    size_t cipherBufferSize = strlen((char *)cipherBuffer);
    
    NSLog(@"decryptWithPrivateKey: length of buffer: %lu", BUFFER_SIZE);
    NSLog(@"decryptWithPrivateKey: length of input: %lu", cipherBufferSize);
    
    // DECRYPTION
    size_t plainBufferSize = BUFFER_SIZE;
    
    //  Error handling
    status = SecKeyDecrypt(privK,
                           kSecPaddingPKCS1,
                           &cipherBuffer[0],
                           cipherBufferSize,
                           &plainBuffer[0],
                           &plainBufferSize
                           );
    NSLog(@"decryption result code: %d (size: %lu)", (int)status, plainBufferSize);
    NSLog(@"FINAL decrypted text: %s", plainBuffer);
    
}

//    char puy[] = "-----BEGIN RSA PUBLIC KEY-----\n"\
//    "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAy8Dbv8prpJ/0kKhlGeJY\n"\
//    "ozo2t60EG8L0561g13R29LvMR5hyvGZlGJpmn65+A4xHXInJYiPuKzrKUnApeLZ+\n"\
//    "vw1HocOAZtWK0z3r26uA8kQYOKX9Qt/DbCdvsF9wF8gRK0ptx9M6R13NvBxvVQAp\n"\
//    "fc9jB9nTzphOgM4JiEYvlV8FLhg9yZovMYd6Wwf3aoXK891VQxTr/kQYoq1Yp+68\n"\
//    "i6T4nNq7NWC+UNVjQHxNQMQMzU6lWCX8zyg3yH88OAQkUXIXKfQ+NkvYQ1cxaMoV\n"\
//    "PpY72+eVthKzpMeyHkBn7ciumk5qgLTEJAfWZpe4f4eFZj/Rc8Y8Jj2IS5kVPjUy\n"\
//    "wQIDAQAB\n"\
//    "-----END RSA PUBLIC KEY-----\n";

    
//    
//    char ttt[] = "-----BEGIN RSA PUBLIC KEY-----"
//    "MIGHAoGBAK5UhSRAOBcLFDK37ghHk8B95OYBoLMG54FlZSJVUVGCRKkTgqfUtsyR"
//    "AC75nxnMR49UfcCA4BxD6E6JqZ/zRpbdvLcXHN70hGBMBPbgK8XdKtd3X7Y/DvfP"
//    "Rm/CGnzSUFe4hpL7chpSu51gGHjwSAoHmxkYtk4mOXlpN6rwv6B1AgED"
//    "-----END RSA PUBLIC KEY-----";
    
    
//    NSRange spos = [outPublicString rangeOfString:@"-----BEGIN RSA PUBLIC KEY-----"];//@"-----BEGIN PUBLIC KEY-----"];
//    NSRange epos = [outPublicString rangeOfString:@"-----END RSA PUBLIC KEY-----"];//@"-----END PUBLIC KEY-----"];
//    if(spos.location != NSNotFound && epos.location != NSNotFound){
//        NSUInteger s = spos.location + spos.length;
//        NSUInteger e = epos.location;
//        NSRange range = NSMakeRange(s, e-s);
//        outPublicString = [outPublicString substringWithRange:range];
//    }
//    
//    outPublicString = [NSString stringWithFormat:@"-----BEGIN PUBLIC KEY-----%@-----END PUBLIC KEY-----\n",outPublicString];
//    
//    NSMutableArray * stringArray = [NSMutableArray array];
//    for (int i = 0; i < [outPublicString length]; i++) {
//        NSString * ch = [outPublicString substringWithRange:NSMakeRange(i, 1)];
//        [stringArray addObject:ch];
//    }
//    
//    const unsigned char * enc_data = (unsigned char *) malloc(stringArray.count);
//    
//
//    enc_data = (__bridge const void * _Nullable)(stringArray);
//    
//    
//    const char * utf8String = [outPublicString UTF8String];
//    
//
//    
//    
//    BIO * pub1 = BIO_new(BIO_s_mem());
//    
//    PEM_write_bio_RSAPublicKey(pub1, rsa_publickey);
//    size_t pub_len1 = BIO_pending(pub1);
//
//    char * pub_key1 = malloc(pub_len + 1);
//    BIO_read(pub1, pub_key1, (int) pub_len1);
//    
//    pub_key1[pub_len1] = '\0';
//
//    
//    
//    size_t len = strlen(utf8String);
//    
//    unsigned char * mac = (unsigned char *)pub_key;
//    
//    RSA * pubRsa = createRSA(mac, 1);
//    
//    
////    NSMutableArray * stringArray = [NSMutableArray array];
////    for (int i = 0; i < [outPublicString length]; i++) {
////        NSString * ch = [outPublicString substringWithRange:NSMakeRange(i, 1)];
////        [stringArray addObject:ch];
////    }
////    
////    const unsigned char * enc_data = (unsigned char *) malloc(stringArray.count+1);
//    
////    char * temp = strdup(word);
////    
////    char * publicKey = [outPublicString cStringUsingEncoding:NSUTF8StringEncoding];
////
////    RSA * pubRsa = createRSA((unsigned char *)enc_data, 1);
//    
//    
//    NSString * test = @"Hello this is Eugene";
//    NSData * data = [test dataUsingEncoding:NSUTF8StringEncoding];
//    int maxSize = RSA_size(MY_RSA);
//    unsigned char *output = (unsigned char *) malloc(maxSize * sizeof(char));
//
//    
//    
////    RSA * pubRsa = createRSA(publicKey_, 1);
//    
//    int bytes = RSA_public_encrypt((int)[data length], [data bytes], output, pubRsa, RSA_PKCS1_PADDING);
//    
//    NSData * result = [NSData dataWithBytes:output length:bytes];
//    
//    NSString * t = [self base64StingFromData:result];
//    
//    NSData * trData = base64_decode(t);
//    
//   
//    unsigned char decrypted[4098]={};
//    RSA_private_decrypt(bytes, output, decrypted, MY_RSA, RSA_PKCS1_PADDING);
//    
//    
//    [self decriptString:testStringEnc];
//}

- (SecKeyRef) getPrivateKey:(NSString *)prKey
{
    NSString * tag = @"adpPrivateKey";

    NSData * d_key = [self addPrivateKeyData:prKey];
    
    if(d_key == nil) return nil;
    
    NSData * d_tag = [NSData dataWithBytes:[tag UTF8String] length:[tag length]];
    
    // Delete any old lingering key with the same tag
    NSMutableDictionary *privateKey = [[NSMutableDictionary alloc] init];
    [privateKey setObject:(id) kSecClassKey forKey:(id)kSecClass];
    [privateKey setObject:(id) kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
    [privateKey setObject:d_tag forKey:(id)kSecAttrApplicationTag];
    SecItemDelete((CFDictionaryRef)privateKey);
    
    CFTypeRef persistKey = nil;
    
    // Add persistent version of the key to system keychain
    [privateKey setObject:d_key forKey:(id)kSecValueData];
    [privateKey setObject:(id) kSecAttrKeyClassPrivate forKey:(id)
     kSecAttrKeyClass];
    [privateKey setObject:[NSNumber numberWithBool:YES] forKey:(id)
     kSecReturnPersistentRef];
    
    OSStatus secStatus = SecItemAdd((CFDictionaryRef)privateKey, &persistKey);
    if (persistKey != nil) CFRelease(persistKey);
    
    if ((secStatus != noErr) && (secStatus != errSecDuplicateItem)) {

        return(nil);
    }
    
    // Now fetch the SecKeyRef version of the key
    SecKeyRef keyRef = nil;
    
    [privateKey removeObjectForKey:(id)kSecValueData];
    [privateKey removeObjectForKey:(id)kSecReturnPersistentRef];
    [privateKey setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecReturnRef
     ];
    [privateKey setObject:(id) kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
    secStatus = SecItemCopyMatching((CFDictionaryRef)privateKey,
                                    (CFTypeRef *)&keyRef);
    
    if(secStatus != noErr)
        return nil;
    
    return keyRef;
}

- (void)decriptString:(NSString *)testString
{
    unsigned char decrypted[4098]={};
    NSMutableArray * stringArray = [NSMutableArray array];
    for (int i = 0; i < [testString length]; i++) {
        NSString * ch = [testString substringWithRange:NSMakeRange(i, 1)];
        [stringArray addObject:ch];
    }
    
    const unsigned char * enc_data = (unsigned char *) malloc(stringArray.count);
    
    enc_data = (__bridge const void * _Nullable)(stringArray);
    
    
    size_t data_len = stringArray.count;
    
    int result = RSA_private_decrypt((int)data_len,enc_data,decrypted,MY_RSA,RSA_PKCS1_PADDING);
    
    
    NSLog(@"AAAAAA /n i = %i /n %s",result,decrypted);
}


//
//
//
//int public_encrypt(unsigned char * data,int data_len,unsigned char * key, unsigned char *encrypted)
//{
//    RSAHelper * rsa = createRSA(key,1);
//    int result = RSA_public_encrypt(data_len,data,encrypted,rsa,RSA_PKCS1_PADDING);
//    return result;
//}
//
//int private_decrypt(unsigned char * enc_data,int data_len,unsigned char * key, unsigned char *decrypted)
//{
//    RSAHelper * rsa = createRSA(key,0);
//    int  result = RSA_private_decrypt(data_len,enc_data,decrypted,rsa,RSA_PKCS1_PADDING);
//    return result;
//}
//
//
//RSAHelper * createRSA(unsigned char * key,int public)
//{
//    RSAHelper *rsa= NULL;
//    BIO *keybio ;
//    keybio = BIO_new_mem_buf(key, -1);
//    if (keybio==NULL)
//    {
//        printf( "Failed to create key BIO");
//        return 0;
//    }
//    if(public)
//    {
//        rsa = PEM_read_bio_RSA_PUBKEY(keybio, &rsa,NULL, NULL);
//    }
//    else
//    {
//        rsa = PEM_read_bio_RSAPrivateKey(keybio, &rsa,NULL, NULL);
//    }
//    
//    return rsa;
//}
//
//





- (NSString *)encryptString:(NSString *)str publicKey:(NSString *)pubKey
{
    NSData * data = [self encryptData:[str dataUsingEncoding:NSUTF8StringEncoding] publicKey:pubKey];
    NSString * ret = base64_encode_data(data);
    return ret;
}

- (NSData *)encryptData:(NSData *)data publicKey:(NSString *)pubKey{
    if(!data || !pubKey){
        return nil;
    }
    SecKeyRef keyRef = [self addPublicKey:pubKey];
    if(!keyRef){
        return nil;
    }
    return [self encryptData:data withKeyRef:keyRef];
}

- (NSData *)encryptData:(NSData *)data withKeyRef:(SecKeyRef) keyRef
{
    const uint8_t *srcbuf = (const uint8_t *)[data bytes];
    size_t srclen = (size_t)data.length;
    
    size_t block_size = SecKeyGetBlockSize(keyRef) * sizeof(uint8_t);
    void *outbuf = malloc(block_size);
    size_t src_block_size = block_size - 11;
    
    NSMutableData * ret = [[NSMutableData alloc] init];
    for(int idx=0; idx<srclen; idx+=src_block_size){
        //NSLog(@"%d/%d block_size: %d", idx, (int)srclen, (int)block_size);
        size_t data_len = srclen - idx;
        if(data_len > src_block_size){
            data_len = src_block_size;
        }
        
        size_t outlen = block_size;
        OSStatus status = noErr;
        status = SecKeyEncrypt(keyRef,
                               kSecPaddingPKCS1,
                               srcbuf + idx,
                               data_len,
                               outbuf,
                               &outlen
                               );
        if (status != 0) {
            NSLog(@"SecKeyEncrypt fail. Error Code: %d", status);
            ret = nil;
            break;
        }else{
            [ret appendBytes:outbuf length:outlen];
        }
    }
    
    free(outbuf);
    CFRelease(keyRef);
    return ret;
}

- (SecKeyRef)addPublicKey:(NSString *)key {
    NSRange spos = [key rangeOfString:@"-----BEGIN RSA PUBLIC KEY-----"];//@"-----BEGIN PUBLIC KEY-----"];
    NSRange epos = [key rangeOfString:@"-----END RSA PUBLIC KEY-----"];//@"-----END PUBLIC KEY-----"];
    if(spos.location != NSNotFound && epos.location != NSNotFound){
        NSUInteger s = spos.location + spos.length;
        NSUInteger e = epos.location;
        NSRange range = NSMakeRange(s, e-s);
        key = [key substringWithRange:range];
    }
    key = [key stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@" "  withString:@""];
    
    // This will be base64 encoded, decode it.
    NSData * data = base64_decode(key);
    
    return [self addPublicKeyFromData:data];
}

- (NSData *)addPrivateKeyData:(NSString *)key {
    NSRange spos = [key rangeOfString:@"-----BEGIN RSA PRIVATE KEY-----"];//@"-----BEGIN PUBLIC KEY-----"];
    NSRange epos = [key rangeOfString:@"-----END RSA PRIVATE KEY-----"];//@"-----END PUBLIC KEY-----"];
    if(spos.location != NSNotFound && epos.location != NSNotFound){
        NSUInteger s = spos.location + spos.length;
        NSUInteger e = epos.location;
        NSRange range = NSMakeRange(s, e-s);
        key = [key substringWithRange:range];
    }
    key = [key stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    key = [key stringByReplacingOccurrencesOfString:@" "  withString:@""];
    
    return base64_decode(key);
}

- (SecKeyRef)addPublicKeyFromData:(NSData *)data {
//    data = [self stripPublicKeyHeader:data];
//    if(!data){
//        return nil;
//    }
    //a tag to read/write keychain storage
    NSString *tag = @"RSAUtil_PubKey";
    NSData *d_tag = [NSData dataWithBytes:[tag UTF8String] length:[tag length]];
    
    // Delete any old lingering key with the same tag
    NSMutableDictionary * publicKey_ = [[NSMutableDictionary alloc] init];
    [publicKey_ setObject:(__bridge id) kSecClassKey forKey:(__bridge id)kSecClass];
    [publicKey_ setObject:(__bridge id) kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [publicKey_ setObject:d_tag forKey:(__bridge id)kSecAttrApplicationTag];
    SecItemDelete((__bridge CFDictionaryRef)publicKey_);
    
    // Add persistent version of the key to system keychain
    [publicKey_ setObject:data forKey:(__bridge id)kSecValueData];
    [publicKey_ setObject:(__bridge id) kSecAttrKeyClassPublic forKey:(__bridge id)
     kSecAttrKeyClass];
    [publicKey_ setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)
     kSecReturnPersistentRef];
    
    CFTypeRef persistKey = nil;
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)publicKey_, &persistKey);
    if (persistKey != nil){
        CFRelease(persistKey);
    }
    if ((status != noErr) && (status != errSecDuplicateItem)) {
        return nil;
    }
    
    [publicKey_ removeObjectForKey:(__bridge id)kSecValueData];
    [publicKey_ removeObjectForKey:(__bridge id)kSecReturnPersistentRef];
    [publicKey_ setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnRef];
    [publicKey_ setObject:(__bridge id) kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    
    // Now fetch the SecKeyRef version of the key
    SecKeyRef keyRef = nil;
    status = SecItemCopyMatching((__bridge CFDictionaryRef)publicKey_, (CFTypeRef *)&keyRef);
    if(status != noErr){
        return nil;
    }
    return keyRef;
}

- (NSData *)stripPublicKeyHeader:(NSData *)d_key{
    // Skip ASN.1 public key header
    if (d_key == nil) return(nil);
    
    unsigned long len = [d_key length];
    if (!len) return(nil);
    
    unsigned char *c_key = (unsigned char *)[d_key bytes];
    unsigned int  idx	 = 0;
    
    if (c_key[idx++] != 0x30) return(nil);
    
    if (c_key[idx] > 0x80) idx += c_key[idx] - 0x80 + 1;
    else idx++;
    
    // PKCS #1 rsaEncryption szOID_RSA_RSA
    static unsigned char seqiod[] =
    { 0x30,   0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01,
        0x01, 0x05, 0x00 };
    if (memcmp(&c_key[idx], seqiod, 15)) return(nil);
    
    idx += 15;
    
    if (c_key[idx++] != 0x03) return(nil);
    
    if (c_key[idx] > 0x80) idx += c_key[idx] - 0x80 + 1;
    else idx++;
    
    if (c_key[idx++] != '\0') return(nil);
    
    // Now make a new NSData from this buffer
    return([NSData dataWithBytes:&c_key[idx] length:len - idx]);
}

static NSString *base64_encode_data(NSData *data){
    data = [data base64EncodedDataWithOptions:0];
    NSString *ret = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return ret;
}

static NSData *base64_decode(NSString *str) {
    NSData *data = [[NSData alloc] initWithBase64EncodedString:str options:NSDataBase64DecodingIgnoreUnknownCharacters];
    return data;
}

#pragma mark OpebSLL funcs

- (NSString *)base64FromString:(NSString *)string
{
    return [self base64StingFromData:[string dataUsingEncoding:NSUTF8StringEncoding]];
}

- (NSString *)base64StingFromData:(NSData *)stringData
{
    BIO *mem = BIO_new(BIO_s_mem());
    BIO *b64 = BIO_new(BIO_f_base64());
    BIO_set_flags(b64, BIO_FLAGS_BASE64_NO_NL);

    mem = BIO_push(b64, mem);
    
    NSUInteger length = stringData.length;
    void * buffer = (void *) [stringData bytes];
    int bufferSize = (int)MIN(length, INT_MAX);
    
    NSUInteger count = 0;
    BOOL error = NO;
    
    while (!error && count < length) {
        int result = BIO_write(mem, buffer, bufferSize);
        if (result <= 0) {
            error = YES;
        }
        else {
            count += result;
            buffer = (void *) [stringData bytes] + count;
            bufferSize = (int)MIN((length - count), INT_MAX);
        }
    }
    
    int flush_result = BIO_flush(mem);
    if (flush_result != 1) {
        return nil;
    }
    
    char * base64Pointer;
    NSUInteger base64Length = (NSUInteger) BIO_get_mem_data(mem, &base64Pointer);
    NSData * base64data = [NSData dataWithBytesNoCopy:base64Pointer length:base64Length freeWhenDone:NO];
    NSString *base64String = [[NSString alloc] initWithData:base64data encoding:NSUTF8StringEncoding];
    
    BIO_free_all(mem);
    [self base64ToString:base64String];
    
    return base64String;
}

- (NSString *)base64ToString:(NSString *)string
{
    const char * b64chars = [string UTF8String];
    unsigned char * base64DecodeOutput;
    size_t test;
    Base64Decode(strdup(b64chars), &base64DecodeOutput, &test);
    
    NSUInteger base64Length = (int)calcDecodeLength((const char *)base64DecodeOutput);
    NSData * base64data = [NSData dataWithBytesNoCopy:base64DecodeOutput length:base64Length freeWhenDone:NO];
    NSString * base64String = [[NSString alloc] initWithData:base64data encoding:NSUTF8StringEncoding];

    NSLog(@"RETURNED FROM HELL %@", base64String);
    return base64String;
}

int Base64Decode(char* b64message, unsigned char** buffer, size_t* length)
{
    BIO *bio, *b64;
    
    int decodeLen = (int)calcDecodeLength(b64message);
    *buffer = (unsigned char*)malloc(decodeLen + 1);
    (*buffer)[decodeLen] = '\0';
    
    bio = BIO_new_mem_buf(b64message, -1);
    b64 = BIO_new(BIO_f_base64());
    bio = BIO_push(b64, bio);
    
    BIO_set_flags(bio, BIO_FLAGS_BASE64_NO_NL);
    *length = BIO_read(bio, *buffer, (int)strlen(b64message));
    assert(*length == decodeLen);
    BIO_free_all(bio);
    
    return (0);
}

size_t calcDecodeLength(const char* b64input)
{
    size_t len = strlen(b64input),
    padding = 0;
    
    if (b64input[len-1] == '=' && b64input[len-2] == '=') //last two chars are =
        padding = 2;
    else if (b64input[len-1] == '=') //last char is =
        padding = 1;
    
    return (len*3)/4 - padding;
}

size_t encodeLength(unsigned char * buf, size_t length)
{
    // encode length in ASN.1 DER format
    if (length < 128) {
        buf[0] = length;
        return 1;
    }
    
    size_t i = (length / 256) + 1;
    buf[0] = i + 0x80;
    for (size_t j = 0 ; j < i; ++j) {         buf[i - j] = length & 0xFF;         length = length >> 8;
    }
    
    return i + 1;
}

@end