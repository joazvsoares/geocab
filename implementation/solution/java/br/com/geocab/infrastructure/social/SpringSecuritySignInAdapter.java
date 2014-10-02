package br.com.geocab.infrastructure.social;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.social.connect.Connection;
import org.springframework.social.connect.web.SignInAdapter;
import org.springframework.web.context.request.NativeWebRequest;

import br.com.geocab.domain.entity.account.User;
import br.com.geocab.domain.repository.account.IUserRepository;

/**
 * 
 * @author rodrigo
 */
public class SpringSecuritySignInAdapter implements SignInAdapter
{
	/**
	 * 
	 */
	@Autowired
	private IUserRepository userRepository;
	
	/**
	 * Complete a provider sign-in attempt by signing in the local user account with the specified id.
	 * @param userId the local user id
	 * @param connection the connection
	 * @param request a reference to the current web request; is a "native" web request instance providing access to the native
	 * request and response objects, such as a HttpServletRequest and HttpServletResponse, if needed
	 * @return the URL that ProviderSignInController should redirect to after sign in. May be null, indicating that ProviderSignInController
	 * should redirect to its postSignInUrl.
	 */
	public String signIn( String userId, Connection<?> connection, NativeWebRequest request )
	{
		System.out.println( userId );
		final User user = this.userRepository.findByEmail(userId);
		SecurityContextHolder.getContext().setAuthentication(new UsernamePasswordAuthenticationToken(user, user.getPassword(), user.getAuthorities()));
		
		return null;//redirects to /
	}
}