// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Tokens.sol";

library LibTokensArray {
    function pushValue(uint256[] storage arr, uint256 value) internal returns (uint256 idx) {
        arr.push(value);
        idx = arr.length - 1;
    }

    function removeIdx(uint256[] storage arr, uint256 idx) internal returns (uint256 value) {
        uint256 n = arr.length;
        value = arr[idx];
        if (idx != n - 1) {
            arr[idx] = arr[n - 1];
        }
        arr.pop();
    }
}

abstract contract ERC721F is IERC721 {
    struct TokenInfo {
        address owner;
        uint96 ownerTokenIdx;
    }

    error NotTokenOwnerError();
    error BadRecipientError();
    error NotATokenError();
    error onERC721ReceivedError();
    error UnauthorizedError();

    using LibTokensArray for uint256[];

    uint256 public immutable totalSupply;
    uint256 public immutable q;
    ERC20N public immutable erc20;
    string public name;
    string public symbol;
    mapping (address => mapping (address => bool)) public isApprovedForAll;
    mapping (uint256 => address) public getApproved;
    mapping (address => uint256[]) private _tokensByOwner;
    mapping (uint256 => TokenInfo) private _tokenInfoByTokenId;

    constructor(string memory name_, string memory symbol_, uint256 totalErc20Supply_, uint256 q_) {
        name = name_;
        symbol = symbol_;
        q = q_;
        totalSupply = totalErc20Supply_ / q;
        erc20 = new ERC20N(name, symbol, totalErc20Supply_, q_);
    }

    function balanceOf(address owner) external view returns (uint256) {
        return _tokensByOwner[owner].length;
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        address owner = _tokenInfoByTokenId[tokenId].owner;
        if (owner == address(0)) {
            revert NotATokenError();
        }
        return owner;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == 0xffffffff || interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f;
    }

    function setApprovalForAll(address spender, bool isApproved) external {
        isApprovedForAll[msg.sender][spender] = isApproved;
        emit ApprovalForAll(msg.sender, spender, isApproved);
    }

    function approve(address spender, uint256 tokenId) external {
        getApproved[tokenId] = spender;
        emit Approval(msg.sender, spender, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) external {
        TokenInfo memory info = _tokenInfoByTokenId[tokenId];
        if (info.owner != from) {
            revert NotTokenOwnerError();
        }
        if (to == address(0) || to == address(this)) {
            revert BadRecipientError();
        }
        _transfer(info, to);
        erc20.adjust(from, to, q);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory receiveData) public {
        TokenInfo memory info = _tokenInfoByTokenId[tokenId];
        if (info.owner != from) {
            revert NotTokenOwnerError();
        }
        _transfer(info, to);
        erc20.adjust(from, to, q);
        if (to.code.length != 0) {
            if (
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    receiveData
                ) != IERC721Receiver.onERC721Received.selector
            ) {
                revert onERC721ReceivedError();
            }
        }
    }

    // TODO: erc20.transfer(..., tokenIdxs[]) -> smash(..., tokenIdxs[])
    function smash(address owner, uint256 tokenCount) external {
        if (msg.sender != address(erc20)) {
            revert UnauthorizedError();
        }
        uint256 n = _tokensByOwner[owner].length;
        // TODO: batch
        for (uint256 i = 0; i < tokenCount && n > i; ++i) {
            _transfer(
                _tokenInfoByTokenId[_tokensByOwner[owner][n - i - 1]],
                address(this)
            );
        }
    }

    function form(address owner, uint256 tokenCount) external {
        if (msg.sender != address(erc20)) {
            revert UnauthorizedError();
        }
        uint256 n = _tokensByOwner[address(this)].length;
        // TODO: batch
        for (uint256 i = 0; i < tokenCount; ++i) {
            TokenInfo memory info;
            if (n > i) {
                info = _tokenInfoByTokenId[_tokensByOwner[address(this)][n - i - 1]];
            }
            _transfer(info, owner);
        }
    }

    /// @dev plz no reentrancy in here.
    function _transfer(TokenInfo memory info, address to)
        private
    {
        address from = info.owner;
        uint256 tokenId;
        if (info.ownerTokenIdx >= _tokensByOwner[from].length) {
            tokenId = _mint();
        } else {
            tokenId = _tokensByOwner[from].removeIdx(info.ownerTokenIdx);
        }
        info.owner = to;
        info.ownerTokenIdx = uint96(_tokensByOwner[to].pushValue(tokenId));
        _tokenInfoByTokenId[tokenId] = info;
        emit Transfer(from, to, tokenId);
    }

    function _mint() internal virtual returns (uint256 tokenId);
}

contract ERC20N is IERC20 {
    error OnlyERC721Error();

    string public name;
    string public symbol;
    uint256 public constant decimals = 18;

    ERC721F public immutable erc721;
    uint256 public immutable q;
    uint256 public immutable totalSupply;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => uint256) public balanceOf;

    modifier onlyERC721() {
        if (msg.sender != address(erc721)) {
            revert OnlyERC721Error();
        }
        _;
    }

    constructor(string memory name_, string memory symbol_, uint256 totalSupply_, uint256 q_) {
        name = name_;
        symbol = symbol_;
        totalSupply = totalSupply_;
        q = q_;
        erc721 = ERC721F(msg.sender);
        balanceOf[msg.sender] = totalSupply_;
        emit Transfer(address(0), address(this), totalSupply_);
    }

    function adjust(address from, address to, uint256 amount) external onlyERC721 {
        _adjust(from, to, amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transferFrom(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        if (from == address(erc721) && amount < totalSupply && balanceOf[from] == totalSupply) {
            _adjust(from, to, amount);
        } else {
            _transferFrom(from, to, amount);
        }
        return true;
    }

    function _transferFrom(address from, address to, uint256 amount) private {
        if (msg.sender != from) {
            uint256 a = allowance[from][msg.sender];
            if (a != type(uint256).max) {
                allowance[from][msg.sender] = a - amount;
            }
        }
        {
            uint256 b = balanceOf[from];
            uint256 d = (b / q) - (b - amount) / q;
            if (d != 0) {
                erc721.smash(from, d);
            }
        }
        {
            uint256 b = balanceOf[to];
            uint256 d = (b + amount) / q - (b / q);
            if (d != 0) {
                erc721.form(to, d);
            }
        }
        _adjust(from, to, amount);
    }

    function _adjust(address from, address to, uint256 amount) private {
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }

}