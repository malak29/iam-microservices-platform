# **IAM Microservices Project - Complete Summary**

## **🏗️ Architecture Overview**

We built a **multi-service IAM (Identity and Access Management) system** with the following microservices:

```
Root: iam-microservices/
├── iam-common-utilities/     # Shared library
├── iam-user-service/         # User CRUD operations (Port 8081)
├── iam-auth-service/         # Authentication & JWT (Port 8082)
├── iam-infrastructure/       # Docker orchestration
└── iam-database-postgres/    # Database schema & initialization
```

## **📊 Database Schema**

**PostgreSQL database with these tables:**
- `"user"` - Main user table (UUID primary key)
- `organization` - Organizations
- `department` - Departments within organizations
- `usertype` - User permission levels (SUPER_ADMIN, ORG_ADMIN, DEPT_HEAD, etc.)
- `userstatus` - User account status (ACTIVE, INACTIVE, PENDING, etc.)
- `authtype` - Authentication methods (EMAIL_PASSWORD, GOOGLE_OAUTH, etc.)

**Key relationships:**
- User belongs to organization, department, has usertype, authtype, and userstatus
- All foreign key constraints enforced

## **🔧 1. iam-common-utilities (Shared Library)**

### **Purpose:** Shared code across all microservices

### **Key Files:**

**build.gradle:**
```gradle
plugins {
    id 'java-library'
    id 'org.springframework.boot' version '3.2.0'
}

dependencies {
    api 'org.springframework.boot:spring-boot-starter-web'
    api 'org.springframework.boot:spring-boot-starter-security'
    api 'org.springframework.boot:spring-boot-starter-data-jpa'
    api 'io.jsonwebtoken:jjwt-api:0.11.5'
    // ... other dependencies
}
```

**ApiResponse.java:**
```java
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ApiResponse<T> {
    private boolean success;
    private String message;
    private T data;
    private String error;
    private List<String> errors;
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime timestamp;
    
    // Static factory methods
    public static <T> ApiResponse<T> success(T data, String message) { ... }
    public static <T> ApiResponse<T> error(String error) { ... }
}
```

**User.java (Shared Entity):**
```java
@Entity
@Table(name = "\"user\"")
@Data
@Builder
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID userId;
    private String email;
    private String username;
    private String name;
    private String hashedPassword;
    private Integer orgId;
    private Integer departmentId;
    private Integer userTypeId;
    private Integer authTypeId;
    private Integer userStatusId;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    
    // Auth-specific fields
    private LocalDateTime lastLogin;
    private Integer failedLoginAttempts;
    private Boolean accountLocked;
    private String passwordResetToken;
    // ... more fields
}
```

**UserRepository.java (Shared Repository):**
```java
@Repository
public interface UserRepository extends JpaRepository<User, UUID> {
    Optional<User> findUserByEmail(String email);
    Optional<User> findUserByUsername(String username);
    List<User> findUsersByOrgId(Integer orgId);
    List<User> findUsersByDepartmentId(Integer departmentId);
    
    // Update methods for auth
    @Modifying
    @Query("UPDATE User u SET u.lastLogin = :loginTime WHERE u.userId = :userId")
    void updateUserLastLogin(@Param("userId") UUID userId, @Param("loginTime") LocalDateTime loginTime);
    
    // ... more methods
}
```

**JwtTokenProvider.java:**
```java
@Component
@Slf4j
public class JwtTokenProvider {
    @Value("${jwt.secret}")
    private String jwtSecret;
    
    public String generateToken(String username) { ... }
    public String extractUsername(String token) { ... }
    public Boolean validateToken(String token) { ... }
    public long getExpirationTime() { ... }
    // ... JWT methods
}
```

**Exception Classes:**
```java
// AuthenticationException.java
public class AuthenticationException extends RuntimeException {
    public AuthenticationException(String message) { super(message); }
}

// CustomExceptions.java
public class CustomExceptions {
    public static class UserNotFoundException extends RuntimeException { ... }
    public static class UnAuthorizedException extends RuntimeException { ... }
    public static class ValidationException extends RuntimeException { ... }
    // ... more exceptions
}
```

**GlobalExceptionHandler.java:**
```java
@RestControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(AuthenticationException.class)
    public ResponseEntity<ApiResponse<Object>> handleAuthenticationException(AuthenticationException ex) {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(ApiResponse.error(ex.getMessage()));
    }
    // ... other exception handlers
}
```

**SecurityConfig.java:**
```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
    
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http.csrf(AbstractHttpConfigurer::disable)
            .authorizeHttpRequests(authz -> authz
                .requestMatchers("/api/v1/users/**").permitAll()
                .requestMatchers("/api/v1/auth/**").permitAll()
                .anyRequest().authenticated()
            );
        return http.build();
    }
}
```

## **👤 2. iam-user-service (Port 8081)**

### **Purpose:** User CRUD operations, profile management

### **Key Files:**

**UserServiceApplication.java:**
```java
@SpringBootApplication
@ComponentScan(basePackages = {"com.iam.user", "com.iam.common"})
@EnableJpaRepositories(basePackages = "com.iam.common.repository")
public class UserServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(UserServiceApplication.class, args);
    }
}
```

**UserController.java:**
```java
@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
public class UserController {
    private final UserService userService;
    
    @GetMapping
    public ResponseEntity<ApiResponse<List<UserResponse>>> getAllUsers() { ... }
    
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<UserResponse>> getUserById(@PathVariable UUID id) { ... }
    
    @GetMapping("/email/{email}")
    public ResponseEntity<ApiResponse<UserResponse>> getUserByEmail(@PathVariable String email) { ... }
    
    @PostMapping
    public ResponseEntity<ApiResponse<UserResponse>> createUser(@Valid @RequestBody CreateUserRequest request) { ... }
    
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<UserResponse>> updateUser(@PathVariable UUID id, @RequestBody UpdateUserRequest request) { ... }
    
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<String>> deleteUser(@PathVariable UUID id) { ... }
}
```

**UserService.java:**
```java
@Service
@RequiredArgsConstructor
@Transactional
public class UserService {
    private final UserRepository userRepository;
    private final UserValidationService userValidationService;
    private final UserMappingService userMappingService;
    
    public List<UserResponse> getAllUsers() { ... }
    public UserResponse getUserById(UUID userId) { ... }
    public UserResponse getUserByEmail(String email) { ... }
    public UserResponse createUser(CreateUserRequest request) { ... }
    public UserResponse updateUser(UUID userId, UpdateUserRequest request) { ... }
    public void deleteUser(UUID userId) { ... }
}
```

**DTOs:**
```java
// CreateUserRequest.java
@Data
public class CreateUserRequest {
    @NotBlank private String username;
    @Email private String email;
    @NotBlank private String password;
    @NotBlank private String name;
    @NotNull private Integer orgId;
    @NotNull private Integer departmentId;
    @NotNull private Integer userTypeId;
    @NotNull private Integer authTypeId;
    @NotNull private Integer userStatusId;
}

// UserResponse.java
@Data @Builder
public class UserResponse {
    private String userId;
    private String email;
    private String username;
    private String name;
    private Integer orgId;
    private Integer departmentId;
    private Integer userTypeId;
    private Integer authTypeId;
    private Integer userStatusId;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
```

**application.yml:**
```yaml
server:
  port: 8081
spring:
  application:
    name: iam-user-service
  profiles:
    active: ${SPRING_PROFILES_ACTIVE:dev}
  datasource:
    url: ${DB_URL:jdbc:postgresql://localhost:5432/iam_db}
    username: ${DB_USERNAME:iam_user}
    password: ${DB_PASSWORD:your_password}
  jpa:
    hibernate:
      ddl-auto: validate
```

## **🔐 3. iam-auth-service (Port 8082)**

### **Purpose:** Authentication, JWT tokens, login/logout

### **Key Files:**

**AuthServiceApplication.java:**
```java
@SpringBootApplication
@ComponentScan(basePackages = {"com.iam.auth", "com.iam.common"})
@EnableJpaRepositories(basePackages = "com.iam.common.repository")
public class AuthServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(AuthServiceApplication.class, args);
    }
}
```

**AuthController.java:**
```java
@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
public class AuthController {
    private final AuthService authService;
    
    @PostMapping("/login")
    public ResponseEntity<ApiResponse<LoginResponse>> login(@Valid @RequestBody LoginRequest request) { ... }
    
    @PostMapping("/refresh")
    public ResponseEntity<ApiResponse<LoginResponse>> refreshToken(@Valid @RequestBody RefreshTokenRequest request) { ... }
    
    @PostMapping("/logout")
    public ResponseEntity<ApiResponse<String>> logout(@Valid @RequestBody LogoutRequest request) { ... }
    
    @GetMapping("/health")
    public ResponseEntity<ApiResponse<String>> health() { ... }
}
```

**AuthService.java:**
```java
@Service
@RequiredArgsConstructor
@Transactional
public class AuthService {
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;
    private final RedisTemplate<String, String> redisTemplate;
    
    public LoginResponse login(LoginRequest request) {
        // 1. Find user by email
        // 2. Verify password
        // 3. Check account status/locks
        // 4. Generate JWT tokens
        // 5. Store refresh token in Redis
        // 6. Update last login time
        return LoginResponse.builder()
            .accessToken(accessToken)
            .refreshToken(refreshToken)
            .userInfo(userInfo)
            .build();
    }
    
    public LoginResponse refreshToken(RefreshTokenRequest request) { ... }
    public ApiResponse<String> logout(LogoutRequest request) { ... }
}
```

**DTOs:**
```java
// LoginRequest.java
@Data
public class LoginRequest {
    @Email @NotBlank private String email;
    @NotBlank private String password;
}

// LoginResponse.java
@Data @Builder
public class LoginResponse {
    private String accessToken;
    private String refreshToken;
    private String tokenType = "Bearer";
    private Long expiresIn;
    private UserInfo userInfo;
    private LocalDateTime loginAt;
    
    @Data @Builder
    public static class UserInfo {
        private String userId;
        private String email;
        private String username;
        private String name;
        private Integer orgId;
        private Integer departmentId;
        private String userType;
        private String userStatus;
    }
}
```

**RedisConfig.java:**
```java
@Configuration
public class RedisConfig {
    @Bean
    public RedisTemplate<String, String> redisTemplate(RedisConnectionFactory connectionFactory) {
        RedisTemplate<String, String> template = new RedisTemplate<>();
        template.setConnectionFactory(connectionFactory);
        template.setKeySerializer(new StringRedisSerializer());
        template.setValueSerializer(new StringRedisSerializer());
        return template;
    }
}
```

**application.yml (with environment profiles):**
```yaml
server:
  port: 8082
spring:
  application:
    name: iam-auth-service
  profiles:
    active: ${SPRING_PROFILES_ACTIVE:dev}
  datasource:
    url: ${DB_URL:jdbc:postgresql://localhost:5432/iam_db}
    username: ${DB_USERNAME:iam_user}
    password: ${DB_PASSWORD:your_password}
  data:
    redis:
      host: ${REDIS_HOST:localhost}
      port: ${REDIS_PORT:6379}
      password: ${REDIS_PASSWORD:}

jwt:
  secret: ${JWT_SECRET:your-super-secret-jwt-key}
  expiration-ms: ${JWT_EXPIRATION_MS:86400000}
  refresh-expiration-ms: ${JWT_REFRESH_EXPIRATION_MS:604800000}

auth:
  max-login-attempts: ${AUTH_MAX_LOGIN_ATTEMPTS:5}
  account-lock-duration-minutes: ${AUTH_ACCOUNT_LOCK_DURATION:30}
```

**Multiple environment files:**
- `application-dev.yml` - Development settings
- `application-prod.yml` - Production settings
- `application-test.yml` - Testing settings

## **🐳 4. iam-infrastructure (Docker)**

### **docker-compose.yml:**
```yaml
version: '3.8'
services:
  postgres:
    image: postgres:15
    container_name: iam-postgres
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    ports:
      - "${POSTGRES_PORT}:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ../../iam-database-postgres/init:/docker-entrypoint-initdb.d/
  
  redis:
    image: redis:7-alpine
    container_name: iam-redis
    ports:
      - "${REDIS_PORT}:6379"
    # Note: No password configured (development setup)
  
  iam-adminer:
    image: adminer:latest
    container_name: iam-adminer
    ports:
      - "8080:8080"
    depends_on:
      - postgres
  
  vault:
    image: hashicorp/vault:1.15
    container_name: iam-vault
    ports:
      - "${VAULT_PORT}:8200"
  
  mongodb:
    image: mongo:7
    container_name: iam-mongodb
    ports:
      - "${MONGO_PORT}:27017"
```

### **.env.local:**
```bash
# Database
POSTGRES_DB=iam_db
POSTGRES_USER=iam_user
POSTGRES_PASSWORD=your_password
POSTGRES_PORT=5432

# Redis
REDIS_PORT=6379
# REDIS_PASSWORD not set (no auth for dev)

# Vault
VAULT_PORT=8200
VAULT_ROOT_TOKEN=dev-token

# MongoDB
MONGO_PORT=27017
MONGO_ROOT_USER=admin
MONGO_ROOT_PASSWORD=password
MONGO_DB=iam_chat
```

## **🗄️ 5. iam-database-postgres**

### **Database Schema Files:**
- `01-create-tables.sql` - Creates all tables with proper constraints
- `02-create-indexes.sql` - Performance indexes
- `03-initial-seed.sql` - Reference data (auth types, user statuses, etc.)

**Sample seed data:**
```sql
INSERT INTO authtype (authtypename, description) VALUES 
('EMAIL_PASSWORD', 'Standard email and password authentication'),
('GOOGLE_OAUTH', 'Google OAuth authentication');

INSERT INTO userstatus (userstatusname, description) VALUES 
('ACTIVE', 'Active user account'),
('INACTIVE', 'Inactive user account');

INSERT INTO usertype (usertypename, description, permissionlevel) VALUES 
('SUPER_ADMIN', 'System super administrator', 10),
('ORG_ADMIN', 'Organization administrator', 8),
('DEPT_HEAD', 'Department head/manager', 5),
('DEPT_USER', 'Department regular user', 2);
```

## **🚀 6. Build & Run Scripts**

### **Root settings.gradle:**
```gradle
rootProject.name = 'iam-microservices'
include 'iam-common-utilities'
include 'iam-user-service'
include 'iam-auth-service'
include 'iam-infrastructure'
include 'iam-database-postgres'
```

### **Startup Scripts:**
- `start-iam-services.sh` - Starts Docker infrastructure
- `connect-postgres.sh` - Connects to PostgreSQL

## **📡 API Endpoints**

### **User Service (8081):**
- `GET /api/v1/users` - Get all users
- `GET /api/v1/users/{id}` - Get user by ID
- `GET /api/v1/users/email/{email}` - Get user by email
- `POST /api/v1/users` - Create user
- `PUT /api/v1/users/{id}` - Update user
- `DELETE /api/v1/users/{id}` - Delete user

### **Auth Service (8082):**
- `POST /api/v1/auth/login` - User login
- `POST /api/v1/auth/refresh` - Refresh JWT token
- `POST /api/v1/auth/logout` - User logout
- `GET /api/v1/auth/health` - Health check

## **🔄 Current Architecture Issues**

### **Service Connection:**
- Both services access the same PostgreSQL database directly
- No service-to-service communication
- Shared User entity/repository (good for consistency, but tight coupling)

### **Security:**
- Redis has no password (development setup)
- JWT tokens stored in Redis for session management
- Account lockout after failed login attempts

## **✅ What's Working:**

1. **Complete CRUD operations** for users
2. **JWT-based authentication** with refresh tokens
3. **Redis session management**
4. **Comprehensive exception handling**
5. **Multi-environment configuration** (dev/prod/test)
6. **Docker orchestration** for all infrastructure
7. **Database with proper relationships** and seed data
8. **Shared utilities** to avoid code duplication

## **🎯 Next Steps Discussed:**

1. **API Gateway** - Central routing for all services
2. **Service-to-service communication** - Auth service calls User service
3. **Redis authentication** - Add password for security
4. **Organization/Department services** - Separate microservices
5. **Admin panel workflows** - Super admin → Org admin → Dept head hierarchy

**The foundation is solid and production-ready for expansion!** 🚀